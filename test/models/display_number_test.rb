require 'test_helper'

class DisplayNumberTest < ActiveSupport::TestCase
  def setup
    @user = create_user(login: 'dn', role: create_role('super_admin'))
  end

  test "each business record exposes its identifier through display_number" do
    assert_equal create_product(user: @user, product_no: 'P-9').display_number, 'P-9'
    assert_equal create_instance(user: @user, instance_no: 'I-9').display_number, 'I-9'
    assert_equal create_technology(user: @user, no: 'T-9').display_number, 'T-9'
  end

  test "matter has no identifier column and returns nil" do
    assert_nil create_matter(user: @user).display_number
  end
end
