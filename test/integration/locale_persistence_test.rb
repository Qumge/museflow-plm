require 'test_helper'

class LocalePersistenceTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user(login: 'localer', role: create_role('super_admin'))
  end

  test "switching locale via param records the choice on the user" do
    sign_in_as @user
    assert_nil @user.reload.locale

    get root_path, params: { locale: 'zh-CN' }

    assert_equal 'zh-CN', @user.reload.locale
  end

  test "a later clean request follows the saved locale without a param" do
    @user.update_column(:locale, 'zh-CN')
    sign_in_as @user

    get products_path   # 不带 ?locale=

    assert_includes @response.body, 'lang="zh-CN"'
  end

  test "an anonymous request does not blow up trying to persist" do
    get root_path, params: { locale: 'en' }
    assert_response :success
  end

  test "an invalid locale param is not persisted" do
    @user.update_column(:locale, 'en')
    sign_in_as @user

    get root_path, params: { locale: 'klingon' }

    assert_equal 'en', @user.reload.locale
  end
end
