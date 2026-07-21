# ProductLog / InstanceLog / TechnologyLog 的审批状态机完全一致，
# 唯一差异是 after_active 回写到哪个主记录。各模型用 log_owner 声明即可。
module LogWorkflow
  extend ActiveSupport::Concern

  STATUS = { wait: '草稿', apply: '申请中', develop: '技术已审批',
             flow: '流程化', active: '申请成功', failed: '申请失败' }.freeze

  included do
    include AASM
    include FileConcern

    # lambda 在 relation 上下文求值，name 会拿错，故在类上下文先捕获
    log_model_type = name
    has_many :audits, -> { where(model_type: log_model_type) }, foreign_key: :model_id

    belongs_to :user

    validates_presence_of :develop_id, :flow_id, :active_id

    aasm :status do
      state :wait, initial: true
      state :apply, :develop, :flow, :active, :failed

      event :do_apply do
        transitions from: [:wait, :failed], to: :apply, after: proc { after_apply }
      end
      event :do_develop_audit do
        transitions from: :apply, to: :develop, after: proc { after_develop }
      end
      event :do_flow_audit do
        transitions from: :develop, to: :flow, after: proc { after_flow }
      end
      event :do_active_audit do
        transitions from: :flow, to: :active, after: proc { after_active }
      end
      event :do_failed_audit do
        transitions from: [:apply, :develop, :flow], to: :failed, after: proc { after_failed }
      end
    end
  end

  class_methods do
    # 声明本 Log 归属的主记录关联名，例如 log_owner :product
    def log_owner(name)
      belongs_to name
      define_method(:log_owner_record) { public_send(name) }
    end
  end

  def get_status
    # STATUS's Chinese literals stay as the documented enum + safety-net default;
    # the locale-aware display text is resolved fresh on every call (STATUS being
    # a class-load-time constant, baking I18n.t into it would freeze the result
    # at whatever locale was active when the class first loaded).
    I18n.t(status.to_sym, scope: 'statuses.log_workflow', default: STATUS[status.to_sym]) if status.present?
  end

  def after_apply
    update apply_at: DateTime.now
  end

  def after_develop; end

  def after_flow; end

  def after_failed; end

  def after_active
    update active_at: DateTime.now
    owner = log_owner_record
    # 必须用 attach（共享同一个 blob），不能用 owner.document = document——
    # 后者是赋值，会把 attachment 从 log 移到 owner，log 自己反而丢了文件。
    # 见 test/models/approval_flow_test.rb 里 "回写后 Log 仍持有文件" 的断言。
    owner.document.attach(document.blob) if document.attached?
    owner.update file_path: file_path, file_name: file_name,
                 active_at: DateTime.now, file_user: user
  end
end
