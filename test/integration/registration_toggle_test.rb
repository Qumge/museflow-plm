require 'test_helper'

class RegistrationToggleTest < ActionDispatch::IntegrationTest
  test "sign up is unavailable by default" do
    get new_user_registration_path
    assert_response :redirect
  end

  test "sign up is available when explicitly enabled" do
    ENV['ALLOW_REGISTRATION'] = 'true'
    get new_user_registration_path
    assert_response :success
  ensure
    ENV.delete('ALLOW_REGISTRATION')
  end

  test "an enabled sign up produces an account that can actually sign in" do
    ENV['ALLOW_REGISTRATION'] = 'true'
    post user_registration_path, params: { user: {
      email: 'newbie@example.com', login: 'newbie',
      password: 'password123', password_confirmation: 'password123' } }

    created = User.find_by(login: 'newbie')
    assert created.present?, 'login 必须被强参数放行，否则账号永远无法登录'
    assert created.valid_password?('password123')
  ensure
    ENV.delete('ALLOW_REGISTRATION')
  end
end
