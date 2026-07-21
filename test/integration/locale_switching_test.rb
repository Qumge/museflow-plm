require 'test_helper'

# P4 Task 3：i18n 骨架的端到端回归保护。ApplicationController#set_locale
# 按 params[:locale] > current_user.locale > Accept-Language > 默认语言
# 的优先级解析 I18n.locale；这里既直接断言 I18n.locale 落在哪一级，也用
# Devise 登录失败闪现消息（gem 自带、en/zh-CN 译文都已存在）验证同一个
# HTTP 请求确实渲染出了不同语言的正文，而不只是内部状态切了但没人用到。
class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "defaults to en when nothing hints otherwise" do
    get new_user_session_path
    assert_equal :en, I18n.locale
  end

  test "?locale=zh-CN switches I18n.locale for the request" do
    get new_user_session_path, params: { locale: 'zh-CN' }
    assert_equal :"zh-CN", I18n.locale
  end

  test "?locale=en switches I18n.locale for the request" do
    get new_user_session_path, params: { locale: 'zh-CN' }
    assert_equal :"zh-CN", I18n.locale

    get new_user_session_path, params: { locale: 'en' }
    assert_equal :en, I18n.locale
  end

  test "an unrecognized locale param is ignored, falling through to default" do
    get new_user_session_path, params: { locale: 'fr-FR' }
    assert_equal :en, I18n.locale
  end

  test "end-to-end: same failed-login request renders English vs Chinese flash by locale param" do
    post user_session_path, params: { locale: 'en', user: { login: 'nosuchuser', password: 'wrongpass' } }
    assert_includes flash[:alert], 'Invalid'

    post user_session_path, params: { locale: 'zh-CN', user: { login: 'nosuchuser', password: 'wrongpass' } }
    assert_includes flash[:alert], '错误'
  end

  test "Accept-Language header picks a locale when no param or user preference is given" do
    get new_user_session_path, headers: { 'Accept-Language' => 'zh-CN,zh;q=0.9,en;q=0.8' }
    assert_equal :"zh-CN", I18n.locale
  end

  test "Accept-Language header with no supported locale falls back to default" do
    get new_user_session_path, headers: { 'Accept-Language' => 'fr-FR,fr;q=0.9' }
    assert_equal :en, I18n.locale
  end

  test "signed-in user's stored locale is honored over Accept-Language" do
    user = create_user(login: 'localeuser', role: create_role('super_admin'))
    user.update!(locale: 'zh-CN')
    sign_in_as user

    get root_path, headers: { 'Accept-Language' => 'en' }
    assert_equal :"zh-CN", I18n.locale
  end

  test "explicit locale param overrides the signed-in user's stored locale" do
    user = create_user(login: 'localeuser2', role: create_role('super_admin'))
    user.update!(locale: 'zh-CN')
    sign_in_as user

    get root_path, params: { locale: 'en' }
    assert_equal :en, I18n.locale
  end
end
