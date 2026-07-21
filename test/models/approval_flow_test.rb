require 'test_helper'

# ProductLog / InstanceLog / TechnologyLog 的 AASM 定义完全相同，
# 仅 after_active 回写的父关联不同。P2 会把三者合并到公共 concern，
# 本测试为合并前后提供对照基线。
class ApprovalFlowTest < ActiveSupport::TestCase
  LOGS = {
    'ProductLog'    => { klass: -> { ProductLog },    parent: :create_product,    reader: :product },
    'InstanceLog'   => { klass: -> { InstanceLog },   parent: :create_instance,   reader: :instance },
    'TechnologyLog' => { klass: -> { TechnologyLog }, parent: :create_technology, reader: :technology }
  }.freeze

  def setup
    @user = create_user(login: 'approver', role: create_role('developer'))
  end

  LOGS.each do |name, config|
    define_method("log_at_for_#{name}") do |status|
      parent = send(config[:parent], user: @user)
      create_log(config[:klass].call, parent: parent, user: @user, status: status)
    end

    test "#{name} happy path walks wait to active" do
      log = send("log_at_for_#{name}", 'wait')

      log.do_apply!
      assert_equal 'apply', log.status
      assert_not_nil log.apply_at, 'after_apply 应记录申请时间'

      log.do_develop_audit!
      assert_equal 'develop', log.status

      log.do_flow_audit!
      assert_equal 'flow', log.status

      log.do_active_audit!
      assert_equal 'active', log.status
    end

    test "#{name} activation copies the drawing onto its parent record" do
      log = send("log_at_for_#{name}", 'flow')

      log.do_active_audit!

      parent = log.public_send(config[:reader]).reload
      assert_equal log.file_path, parent.file_path, '生效后图纸应回写到主记录'
      assert_equal log.file_name, parent.file_name
      assert_not_nil parent.active_at
      assert_equal @user, parent.file_user
    end

    # ActiveStorage 迁移后最危险的一处回归：after_active 必须用
    # `owner.document.attach(document.blob)`（共享同一个 blob）而不是
    # `owner.document = document`（赋值会把 attachment 从 log 移到 owner，
    # log 自己反而丢了文件）。上面那个用例只覆盖 file_path/file_name 字符串
    # 镜像，测不出这个区别——document 从未被真正 attach 过，
    # after_active 里 `if document.attached?` 分支根本不会执行。
    # 这里显式挂一个真实文件，专门盯住"回写后 Log 自己是否仍持有文件"。
    test "#{name} activation shares the attached blob with the parent without stripping it from the log" do
      log = send("log_at_for_#{name}", 'flow')
      log.attach_document(io: StringIO.new('pdf bytes'), filename: 'drawing.pdf')
      assert log.document.attached?, '前置条件：Log 挂载文件应该成功'

      log.do_active_audit!

      parent = log.public_send(config[:reader]).reload
      log.reload

      assert parent.document.attached?, '生效后主记录应该拿到文件'
      assert log.document.attached?, 'Log 自己的文件不应该在回写后丢失（不能是移动，必须是共享）'
      assert_equal log.document.blob_id, parent.document.blob_id, '主记录与 Log 应共享同一个 blob，而不是各自持有一份'
    end

    test "#{name} rejects skipping an audit step" do
      assert_raises(AASM::InvalidTransition, 'wait 不能直接进入 develop') do
        send("log_at_for_#{name}", 'wait').do_develop_audit!
      end
      assert_raises(AASM::InvalidTransition, 'apply 不能跳过 develop 直接 flow') do
        send("log_at_for_#{name}", 'apply').do_flow_audit!
      end
      assert_raises(AASM::InvalidTransition, 'develop 不能跳过 flow 直接 active') do
        send("log_at_for_#{name}", 'develop').do_active_audit!
      end
    end

    test "#{name} can be rejected from every in-flight state" do
      %w[apply develop flow].each do |state|
        log = send("log_at_for_#{name}", state)
        log.do_failed_audit!
        assert_equal 'failed', log.status, "#{state} 应可被驳回"
      end
    end

    test "#{name} allows a rejected log to be resubmitted" do
      log = send("log_at_for_#{name}", 'failed')

      log.do_apply!

      assert_equal 'apply', log.status
    end

    test "#{name} refuses to reject an already active log" do
      assert_raises(AASM::InvalidTransition) do
        send("log_at_for_#{name}", 'active').do_failed_audit!
      end
    end
  end
end
