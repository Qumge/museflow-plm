require 'test_helper'

class SeedsTest < ActiveSupport::TestCase
  # 每个 test 各自 load、各自在事务内回滚，互不影响。
  # seed 必须幂等：CI 或 docker 重启会重复跑，不能报错也不能翻倍。
  def load_seed
    load Rails.root.join('db', 'seeds.rb')
  end

  test "loading the seed twice leaves the same counts" do
    load_seed
    counts = { users: User.count, products: Product.count,
               organizations: Organization.count }

    load_seed

    assert_equal counts[:users], User.count, 'seed 重复执行不应新增用户'
    assert_equal counts[:products], Product.count
    assert_equal counts[:organizations], Organization.count
  end

  test "the seed produces a working demo super admin" do
    load_seed
    admin = User.find_by(login: 'admin')

    assert admin.present?
    assert admin.has_role?('super_admin')
    assert admin.valid_password?('password123')
  end

  test "the seed gives every business line something to show" do
    load_seed

    assert Product.exists?
    assert Instance.exists?
    assert Technology.exists?
    assert Matter.exists?
  end
end
