require 'test_helper'

# P4 Task 1（回归测试网）Step 3。
#
# app/views/matters/_countersign.html.erb:21 用
# `user_matter.format_agree == '待确认'` 决定要不要渲染会签按钮。
# `format_agree`（app/models/user_matter.rb）把 `agree` 三态
# （nil/true/false）映射成中文显示串 '待确认'/'已确认'/'失败'。
#
# 这一处**不在** Task 1 的"现在就失败"名单里——P4 Task 2c 要把判定条件改成
# `user_matter.agree.nil?`（语言无关），而不是翻译 `format_agree` 的返回值，
# 所以此刻这条中文比较仍然是对的，本测试现在就应该通过。它守护的是
# Task 2c 改造前后行为完全不变：`agree` 为 nil 时按钮必须还在，
# 为 true 时必须还是不在。
class CountersignTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user(login: 'countersign_signer', role: create_role('countersign_role', resource_specs: :all))
    sign_in_as @user
    # tab_3（会签）以及 _countersign partial 本身只在 status != 'circulation'
    # 时渲染（见 matters/show.html.erb），所以不能用 create_matter 的默认状态。
    @matter = create_matter(user: @user, status: 'countersign')
  end

  test "countersign button is present when UserMatter#agree is nil" do
    UserMatter.create!(user: @user, matter: @matter, agree: nil)

    get matter_path(@matter)

    assert_response :success
    assert_select "button#agree", 1
  end

  test "countersign button is absent when UserMatter#agree is true" do
    UserMatter.create!(user: @user, matter: @matter, agree: true)

    get matter_path(@matter)

    assert_response :success
    assert_select "button#agree", 0
  end
end
