require 'test_helper'

class HomeNoRoleTest < ActionDispatch::IntegrationTest
  test "a user without a role is told so instead of seeing a blank dashboard" do
    roleless = create_user(login: 'noroleuser', role: create_role('empty', resource_specs: :none))
    sign_in_as roleless

    get root_path

    assert_response :success
    assert_match I18n.t('home.no_role_notice'), response.body
  end

  # 回归用例：super_admin 的权限来自 Ability 里硬编码的 `can :manage, :all`
  # （对 has_role?('super_admin') 无条件成立），从不经过逐条 resources 授权
  # ——config/role_resources.yml 里根本没有 super_admin 这个顶层键，
  # Role.load! 建出来的 super_admin 角色在真实种子数据里本来就是零
  # resources（用运行中的 server + 演示账号 admin 实测确认，
  # `User.find_by(login: 'admin').resources.blank?` => true）。第一版实现
  # 只判断 `role.blank? || resources.blank?`，会把超级管理员自己也误判成
  # "无角色"，登录后看到提示而不是仪表盘。
  #
  # 这里必须显式传 resource_specs: :none 来复现——test/support/builders.rb
  # 的 create_role 默认给新角色挂【全部】resources（resource_specs: :all），
  # 这个默认值本身就掩盖了这个 bug：如果不传 :none，测试里的 super_admin
  # 会意外拿到一堆 resources，resources.blank? 恒为 false，回归测试就是
  # 假阳性、抓不到这条真实存在于生产种子数据里的缺陷。
  test "a super_admin is not told they have no role, even though they carry zero itemised resources" do
    admin = create_user(login: 'superadmin', role: create_role('super_admin', resource_specs: :none))
    assert admin.resources.blank?, '前提断言：这个 super_admin 角色必须真的是零 resources，否则下面的断言测不出第一版的 bug'

    sign_in_as admin

    get root_path

    assert_response :success
    assert_no_match I18n.t('home.no_role_notice'), response.body
  end
end
