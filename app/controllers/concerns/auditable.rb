# 三个控制器的 12 个审批动作方法体逐字相同。
#
# 注意：必须用 define_method 生成 4 个【真实的 action 名】，不能合并成一个
# 带 phase 参数的 do_audit —— ApplicationController#authorize_action! 用
# action_name 去 config/resources.yml 查表，改名即失权（全部非超管用户 403）。
module Auditable
  extend ActiveSupport::Concern

  AUDIT_PHASES = %w[develop flow active failed].freeze

  included do
    before_action :set_audit_log,
                  only: AUDIT_PHASES.map { |phase| :"do_#{phase}_audit" }
  end

  AUDIT_PHASES.each do |phase|
    define_method("do_#{phase}_audit") do
      run_audit_transition!("do_#{phase}_audit!")
    end
  end

  private

  def run_audit_transition!(event)
    from_status = @log.status
    @log.public_send(event)
    @log.audits.create from_status: from_status, to_status: @log.status, user: current_user
    @flag = true
  rescue => e
    # 保持原行为：审批失败只置 @flag，不向上抛。原代码连日志都没有，
    # 这里补一行 warn 以便排查——不改变对调用方的可观察行为。
    logger.warn "audit transition #{event} failed for #{@log.class}##{@log&.id}: #{e.class}: #{e.message}"
    @flag = false
  ensure
    render js: 'location.reload()'
  end

  def audit_log_class
    "#{controller_name.singularize.camelize}Log".constantize
  end

  def set_audit_log
    @log = audit_log_class.find_by id: params[:id]
    redirect_to send("#{controller_name}_path"), alert: t('flash.not_found') unless @log.present?
  end
end
