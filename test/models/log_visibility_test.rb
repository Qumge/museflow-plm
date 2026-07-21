require 'test_helper'

# P4 Task 2e。
#
# `has_product_log_resource?` / `has_instance_log_resource?` /
# `has_technology_log_resource?`（app/models/user.rb）此前用中文 name 查一条
# 从未在 config/resources.yml 里声明过的权限（'产品-所有文件记录' 等），
# find_by 恒为 nil，导致这三个方法对所有非 super_admin 用户恒为 false，
# 而 Product#view_logs / Instance#view_logs / Technology#view_logs（各自的
# app/models/*.rb）正是靠这三个方法决定"看全部记录"还是"只看自己的记录"，
# 于是这条"看全部"的能力实际上无法被任何角色获得。
#
# 修复方案：config/resources.yml 新增 products/instances/technologies 各一条
# view_all_logs（非路由 action，不影响"每个可路由 action 都必须声明"这条
# 不变量），config/role_resources.yml 只把三条都授予 develop_manager（研发
# 管理——非超管里权限最高的角色，符合最小权限原则），user.rb 三个方法改成
# 按语言无关的 (target, action) 查，不再依赖会被翻译的中文 name。
#
# 本文件覆盖：develop_manager 三个 has_*_log_resource? 均为真、developer
# 均为假、super_admin 均为真；以及 view_logs 在三个模型上的两个分支都能
# 走到（develop_manager 看到全部记录，developer 只看到自己上传的记录）。
class LogVisibilityTest < ActiveSupport::TestCase
  def setup
    Role.load!
    Resource.load!
    RoleResource.load!
    absorb_first_user_promotion!
    @manager_role = Role.find_by(desc: 'develop_manager')
    @developer_role = Role.find_by(desc: 'developer')
    @admin_role = Role.find_by(desc: 'super_admin')
  end

  test "develop_manager has all three log resources" do
    manager = create_user(login: 'manager', role: @manager_role)

    assert manager.has_product_log_resource?
    assert manager.has_instance_log_resource?
    assert manager.has_technology_log_resource?
  end

  test "developer has none of the three log resources" do
    developer = create_user(login: 'plain-dev', role: @developer_role)

    assert_not developer.has_product_log_resource?
    assert_not developer.has_instance_log_resource?
    assert_not developer.has_technology_log_resource?
  end

  test "super_admin has all three log resources regardless of the manifest" do
    admin = create_user(login: 'admin', role: @admin_role)

    assert admin.has_product_log_resource?
    assert admin.has_instance_log_resource?
    assert admin.has_technology_log_resource?
  end

  test "product view_logs shows every record to a develop_manager user" do
    manager = create_user(login: 'manager-product', role: @manager_role)
    owner = create_user(login: 'owner-product', role: @developer_role)
    product = create_product(user: owner)
    own_log = create_product_log(product: product, user: owner)
    other_log = create_product_log(product: product, user: manager)

    visible = product.view_logs(manager)

    assert_includes visible, own_log
    assert_includes visible, other_log
  end

  test "product view_logs restricts a developer user to their own records" do
    developer = create_user(login: 'dev-product', role: @developer_role)
    other = create_user(login: 'other-product', role: @developer_role)
    product = create_product(user: developer)
    own_log = create_product_log(product: product, user: developer)
    other_log = create_product_log(product: product, user: other)

    visible = product.view_logs(developer)

    assert_includes visible, own_log
    assert_not_includes visible, other_log
  end

  test "instance view_logs shows every record to a develop_manager user" do
    manager = create_user(login: 'manager-instance', role: @manager_role)
    owner = create_user(login: 'owner-instance', role: @developer_role)
    instance = create_instance(user: owner)
    own_log = create_log(InstanceLog, parent: instance, user: owner)
    other_log = create_log(InstanceLog, parent: instance, user: manager)

    visible = instance.view_logs(manager)

    assert_includes visible, own_log
    assert_includes visible, other_log
  end

  test "instance view_logs restricts a developer user to their own records" do
    developer = create_user(login: 'dev-instance', role: @developer_role)
    other = create_user(login: 'other-instance', role: @developer_role)
    instance = create_instance(user: developer)
    own_log = create_log(InstanceLog, parent: instance, user: developer)
    other_log = create_log(InstanceLog, parent: instance, user: other)

    visible = instance.view_logs(developer)

    assert_includes visible, own_log
    assert_not_includes visible, other_log
  end

  test "technology view_logs shows every record to a develop_manager user" do
    manager = create_user(login: 'manager-tech', role: @manager_role)
    owner = create_user(login: 'owner-tech', role: @developer_role)
    technology = create_technology(user: owner)
    own_log = create_log(TechnologyLog, parent: technology, user: owner)
    other_log = create_log(TechnologyLog, parent: technology, user: manager)

    visible = technology.view_logs(manager)

    assert_includes visible, own_log
    assert_includes visible, other_log
  end

  test "technology view_logs restricts a developer user to their own records" do
    developer = create_user(login: 'dev-tech', role: @developer_role)
    other = create_user(login: 'other-tech', role: @developer_role)
    technology = create_technology(user: developer)
    own_log = create_log(TechnologyLog, parent: technology, user: developer)
    other_log = create_log(TechnologyLog, parent: technology, user: other)

    visible = technology.view_logs(developer)

    assert_includes visible, own_log
    assert_not_includes visible, other_log
  end
end
