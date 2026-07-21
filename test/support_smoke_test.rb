require 'test_helper'

class SupportSmokeTest < ActiveSupport::TestCase
  test "builders produce a non-admin user with scoped resources" do
    role = create_role('developer', resource_specs: [%w[index products]])
    user = create_user(login: 'builder-smoke', role: role)

    assert_not user.has_role?('super_admin'), '被测用户不应意外获得 super_admin'
    assert_equal 1, user.resources.size
    assert Ability.new(user).can?(:index, :products)
    assert_not Ability.new(user).can?(:destroy, :products)
  end

  test "product log builder satisfies required approver validations" do
    user = create_user(login: 'log-smoke', role: create_role('developer'))
    log = create_product_log(product: create_product(user: user), user: user)

    assert log.persisted?
    assert_equal 'wait', log.status
  end
end
