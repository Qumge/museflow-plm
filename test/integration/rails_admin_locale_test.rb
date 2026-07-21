require 'test_helper'

# 额外发现的缺口（P4 Task 7 收尾）：RailsAdmin::ApplicationController 默认继承
# ActionController::Base，不继承本应用的 ApplicationController，所以
# LocaleSelectable#set_locale（原来是 ApplicationController 里的私有方法，见
# app/controllers/concerns/locale_selectable.rb）从来没有机会在 rails_admin
# 请求上跑一遍。I18n.locale 是进程内的线程局部状态：不设置不等于落回默认
# 语言，而是直接沿用"这个线程上一次处理的、随便哪个请求"留下的值——在
# 把 rails_admin 的 label 从硬编码中文 DSL 换成 I18n（Task 7）之前这是
# 无法观察到的（反正 DSL 输出的字符串永远是中文字面量，不看 I18n.locale）；
# Task 7 之后，如果不把 set_locale 也接到 RailsAdmin::ApplicationController
# 上，管理后台会随机显示"上一个处理过这个线程的请求"留下的语言，与当前
# 用户请求的 locale 或默认语言都可能对不上。
#
# 这里不追求真的起两个线程并发——Rails 集成测试本来就是同线程顺序执行，
# 复现不了 Puma 多线程下的竞态；而是直接把 I18n.locale 摆成一个"别的请求
# 留下的脏值"，验证 rails_admin 请求会不会把它冲掉、冲成正确的值，这就是
# set_locale 有没有跑到的唯一可观察结果。
class RailsAdminLocaleTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_user(login: 'admin_locale_test', role: create_role('super_admin'))
  end

  test "a rails_admin request resets I18n.locale instead of inheriting a stale value from a prior request" do
    sign_in_as(@admin)

    # 模拟"这个线程上一次处理的是另一个用户/另一个请求，留下 zh-CN"。
    I18n.locale = :"zh-CN"

    get '/admin/user'
    assert_response :success

    assert_equal :en, I18n.locale,
                 'GET /admin/user with no locale param, no Accept-Language and no stored user ' \
                 'preference must fall back to the app default (:en), not silently inherit ' \
                 "whatever locale a previous, unrelated request left on this thread."
    # "帐号"/"部门" 是 config/locales/zh-CN/model.yml 里 user.login /
    # user.organization 的翻译（Task 7 新补的两条，rails_admin 的 User 表单
    # 原生读取），不看具体某一条 Role 记录的 name 列内容——create_role 这个
    # 测试 builder 本来就不会像 Role.load! 那样把 desc 映射回中文 value。
    assert_no_match(/帐号|部门/, response.body,
                     'field labels must render in English once I18n.locale is en, not leak the ' \
                     'zh-CN translations added for the rails_admin User form in P4 Task 7')
    assert_match(/Login/, response.body)
  end

  test "?locale=zh-CN on a rails_admin request is honored, same as the rest of the app" do
    sign_in_as(@admin)
    I18n.locale = :en

    get '/admin/user', params: { locale: 'zh-CN' }
    assert_response :success

    assert_equal :"zh-CN", I18n.locale
    assert_match(/帐号/, response.body,
                 'switching to zh-CN must still work for rails_admin, not just default to en')
  end

  test "set_locale runs before rails_admin's own authentication check" do
    # 不登录，直接访问后台首页；如果 set_locale 排在 _authenticate! 之后
    # 才跑，这条未授权跳转带的 flash 会用错语言（复现 P4 Task 3 已经在
    # ApplicationController 里踩过、并特意注释强调的同一类问题：
    # "排在最前面：locale 不该依赖登录状态"，这里是 rails_admin 那一份
    # 遗漏的对应情形）。
    get '/admin', params: { locale: 'zh-CN' }
    assert_response :redirect
    assert_equal I18n.t('flash.unauthorized', locale: :"zh-CN"), flash[:alert]
  end
end
