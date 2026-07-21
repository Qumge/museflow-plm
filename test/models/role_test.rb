require 'test_helper'

# P4 收尾发现的缺口：ROLES 的中文 value 被 Role.load! 写进 roles.name 列后
# 就再也不会回写（见 app/models/role.rb#load!），侧边栏原来直接渲染
# `current_user.role&.name`，所以切换语言对角色名不生效——英文 locale 下
# 侧边栏仍然显示"超级管理员"。
class RoleTest < ActiveSupport::TestCase
  setup do
    @previous_locale = I18n.locale
  end

  teardown do
    I18n.locale = @previous_locale
  end

  test "display_name follows the current locale regardless of the stored name column" do
    role = Role.create!(name: '超级管理员', desc: 'super_admin')

    I18n.locale = :en
    assert_equal 'Super Admin', role.display_name

    I18n.locale = :'zh-CN'
    assert_equal '超级管理员', role.display_name
  end

  test "display_name covers every seeded role in both locales" do
    Role::ROLES.each_key do |desc|
      role = Role.create!(name: Role::ROLES[desc], desc: desc.to_s)

      I18n.locale = :en
      assert_match(/[A-Za-z]/, role.display_name,
                   "#{desc} should translate to an English label, got #{role.display_name.inspect}")

      I18n.locale = :'zh-CN'
      assert_equal Role::ROLES[desc], role.display_name
    end
  end

  test "display_name falls back to the stored name for a role outside ROLES" do
    role = Role.create!(name: 'Custom Role', desc: 'custom_role')

    I18n.locale = :en
    assert_equal 'Custom Role', role.display_name
  end

  test "display_name falls back to the raw name when desc is blank" do
    role = Role.new(name: 'Nameless')

    assert_equal 'Nameless', role.display_name
  end
end
