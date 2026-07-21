require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  def setup
    Role.load!
    Resource.load!
    # 第一个创建的用户会被 User#assign_super_admin_if_first_user 提权为超管，
    # 先创建一个占位用户吸收该副作用，保证后续被测用户是普通角色。
    User.create!(email: 'first@example.com', login: 'first',
                 password: 'password123', password_confirmation: 'password123')
    @role = Role.find_by(desc: 'developer')
  end

  def build_user_with(resources)
    @role.resources = Array(resources)
    @role.save!
    User.create!(email: "subject-#{SecureRandom.hex(4)}@example.com",
                 login: "subject-#{SecureRandom.hex(4)}",
                 password: 'password123', password_confirmation: 'password123',
                 role: @role)
  end

  test "grants a permission declared in the resources manifest" do
    resource = Resource.find_by!(target: 'products', action: 'index')
    ability = Ability.new(build_user_with(resource))
    assert ability.can?(:index, :products)
  end

  test "ignores a resource row absent from the manifest" do
    rogue = Resource.create!(target: 'products', action: 'destroy_everything', name: 'rogue')
    ability = Ability.new(build_user_with(rogue))
    assert_not ability.can?(:destroy_everything, :products)
  end

  test "never evaluates resource content as ruby code" do
    payload = Resource.create!(target: 'products',
                               action: "index, :all; $ability_rce_marker = true",
                               name: 'payload')
    $ability_rce_marker = nil
    Ability.new(build_user_with(payload))
    assert_nil $ability_rce_marker,
               "resource columns must never reach eval — this is the RCE guard"
  end

  test "super_admin still manages everything" do
    admin = User.create!(email: 'admin-test@example.com', login: 'admin-test',
                         password: 'password123', password_confirmation: 'password123',
                         role: Role.find_by(desc: 'super_admin'))
    assert Ability.new(admin).can?(:manage, :all)
  end
end
