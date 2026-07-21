require 'test_helper'

# 这条守护的是一个 123 个测试全绿却没能拦住的回归：
#
# LocaleSelectable 用 `before_action :set_locale, prepend: true` 把自己排到
# 最前，而 set_locale 会读 current_user 取语言偏好——那会在 CSRF 校验之前
# 触发 Warden 认证并搅动会话，使真实浏览器的登录 POST 一律 422。
#
# 集成测试默认关掉了 forgery protection，所以整个套件都发现不了。这里显式
# 打开它，走一次带真实 token 的完整登录。
class SignInCsrfTest < ActionDispatch::IntegrationTest
  def setup
    @original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    @user = create_user(login: 'csrfuser', role: create_role('super_admin'))
  end

  def teardown
    ActionController::Base.allow_forgery_protection = @original
  end

  test "signing in with the form's authenticity token succeeds" do
    get new_user_session_path
    assert_response :success

    token = css_select('input[name=authenticity_token]').first&.[]('value')
    assert token.present?, '登录表单里应该有 authenticity_token'

    post user_session_path, params: {
      authenticity_token: token,
      user: { login: @user.login, password: 'password123' }
    }

    assert_response :redirect,
                    'CSRF 校验必须排在 set_locale 之前，否则登录一律 422'
  end
end
