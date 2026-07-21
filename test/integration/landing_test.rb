require 'test_helper'

class LandingTest < ActionDispatch::IntegrationTest
  test "visitors see the landing page at the root" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", new_user_session_path
  end

  test "signed-in users go straight to the dashboard" do
    user = create_user(login: 'landing', role: create_role('super_admin'))
    sign_in_as user

    get root_path

    assert_response :success
    assert_select "aside"   # 仪表盘布局有侧边栏，落地页没有
  end
end
