require 'test_helper'

# P4 Task 1（回归测试网）Step 4，P4 Task 2d 改写。
#
# `UserNotice.search_conn`（app/models/user_notice.rb）原先用四个中文
# 魔法值 '未读'/'已读'/'未回复'/'已回复' 分支过滤，且这四个值与
# params[:table_search]（通用检索框）共用同一个参数——用户想按状态筛选，
# 只能在检索框里照抄状态列文字，而且抄的 '未回复' 与状态列实际显示的
# '待回复' 本就对不上（既有 bug）。
#
# Task 2d 把状态过滤改成独立的 params[:status]，取值为语言无关的英文枚举
# unread/read/unreplied/replied（UserNotice::STATUSES），与
# params[:table_search] 的自由文本检索彻底分开。本文件覆盖的过滤语义与
# Task 1 版本完全相同，只是改用新参数名和新枚举值。
#
# 四条 fixture 记录刻意让 readed / need_reply / replied 三个维度互不重叠
# （除了"已读"这个分支本就与"未回复"/"已回复"在语义上有交集——readed 和
# replied 是两个独立维度，一条通知可以同时是"已读"又是"未回复"，这是被测
# 方法本身的真实行为，不是本测试的假设），使每个分支的期望结果集清晰、
# 可断言。
class UserNoticeSearchTest < ActiveSupport::TestCase
  def setup
    @creator = create_user(login: 'notice_author')
    @recipient = create_user(login: 'notice_recipient')

    fyi_a = Notice.create!(user: @creator, title: 'FYI A', content: 'body', need_reply: false)
    fyi_b = Notice.create!(user: @creator, title: 'FYI B', content: 'body', need_reply: false)
    ask_a = Notice.create!(user: @creator, title: 'Please reply A', content: 'body', need_reply: true)
    ask_b = Notice.create!(user: @creator, title: 'Please reply B', content: 'body', need_reply: true)

    # 未读：readed 为 nil/false，need_reply 与本分支无关。
    @unread = UserNotice.create!(user: @recipient, notice: fyi_a, readed: nil, replied: nil)

    # 已读：readed 为 true。need_reply 为 false，避免与未回复/已回复混淆。
    @read = UserNotice.create!(user: @recipient, notice: fyi_b, readed: true, replied: nil)

    # 未回复：notice.need_reply 为 true 且 replied 为 nil/false。
    # readed 设为 true，使其不落入"未读"分支，让每个分支的期望结果集互斥、
    # 便于断言（该方法真实语义里未读与未回复本可同时成立，这里只是为了
    # 测试断言的清晰度而选择了这组输入）。
    @unreplied = UserNotice.create!(user: @recipient, notice: ask_a, readed: true, replied: nil)

    # 已回复：notice.need_reply 为 true 且 replied 为 true。
    @replied = UserNotice.create!(user: @recipient, notice: ask_b, readed: true, replied: true)
  end

  test "status=unread returns only rows that have not been read" do
    result = UserNotice.search_conn(status: 'unread')

    assert_equal [@unread.id], result.pluck(:id)
  end

  test "status=read returns rows that have been read" do
    result = UserNotice.search_conn(status: 'read')

    assert_equal [@read.id, @unreplied.id, @replied.id].sort, result.pluck(:id).sort
  end

  test "status=unreplied returns rows whose notice needs a reply and has not been replied to" do
    result = UserNotice.search_conn(status: 'unreplied')

    assert_equal [@unreplied.id], result.pluck(:id)
  end

  test "status=replied returns rows whose notice needed a reply and has been replied to" do
    result = UserNotice.search_conn(status: 'replied')

    assert_equal [@replied.id], result.pluck(:id)
  end

  test "an unrecognized status falls back to the free-text table_search branch" do
    # 该分支的 `users.name` 来自 joins(notice: :user)，即通知的发起人
    # （@creator），而不是收件人（@recipient）——四条 fixture 通知都由
    # @creator 发起，故按其姓名搜索应命中全部四条。
    result = UserNotice.search_conn(status: nil, table_search: @creator.name)

    assert_equal [@unread, @read, @unreplied, @replied].map(&:id).sort, result.pluck(:id).sort
  end

  test "a blank status and table_search returns everything" do
    result = UserNotice.search_conn({})

    assert_equal [@unread, @read, @unreplied, @replied].map(&:id).sort, result.pluck(:id).sort
  end

  test "status takes precedence over a concurrently present table_search" do
    # 状态下拉与检索框是两个独立控件，同一次提交里两者都可能带值；
    # status 存在时按状态过滤，table_search 被忽略——这是 Task 2d 新增的
    # 行为约定（Task 1 版本二者本就是同一个参数，没有这种组合场景）。
    result = UserNotice.search_conn(status: 'unread', table_search: @creator.name)

    assert_equal [@unread.id], result.pluck(:id)
  end
end
