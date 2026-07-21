require 'test_helper'

class AuthorizationTest < ActionDispatch::IntegrationTest
  def setup
    @zero = create_user(login: 'zeroperm', role: create_role('zero_perm', resource_specs: :none))
    @admin = create_user(login: 'superadmin', role: create_role('super_admin'))
  end

  test "zero-permission user cannot read business index pages" do
    sign_in_as @zero

    %w[/products /instances /technologies /matters /audits].each do |path|
      get path
      assert_redirected_to root_path, "#{path} 必须拒绝零权限用户，实际状态 #{response.status}"
    end
  end

  test "zero-permission user cannot destroy a product" do
    product = create_product(user: @admin)
    sign_in_as @zero

    assert_no_difference 'Product.count', '零权限用户绝不能删除数据' do
      delete product_path(product)
    end
    assert_redirected_to root_path
  end

  test "zero-permission user cannot advance an approval" do
    product = create_product(user: @admin)
    log = create_product_log(product: product, user: @admin, status: 'apply')
    sign_in_as @zero

    post do_develop_audit_products_path, params: { id: log.id }

    assert_equal 'apply', log.reload.status, '零权限用户绝不能推进审批状态'
    assert_redirected_to root_path
  end

  test "user with the matching resource is allowed through" do
    role = create_role('reader', resource_specs: [%w[index products]])
    reader = create_user(login: 'reader', role: role)
    sign_in_as reader

    get products_path
    assert_response :success
  end

  test "super_admin retains full access" do
    sign_in_as @admin

    get products_path
    assert_response :success
  end

  test "sign-in page stays reachable without authorization" do
    get new_user_session_path
    assert_response :success
  end
end
