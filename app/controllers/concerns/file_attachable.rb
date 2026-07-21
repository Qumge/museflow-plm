# 三个控制器的文件上传/编辑/申请动作是 A 类重复——唯一变量是 owner 关联名，
# 可由 controller_name 推导。
#
# 不下沉：<x>_permit（三者字段集互不相同）、import/do_import（实现完全不同）。
module FileAttachable
  extend ActiveSupport::Concern

  included do
    before_action :set_log, only: [:edit_file, :update_file, :apply, :do_apply]
  end

  def upload_file
    render layout: false
  end

  def do_upload_file
    @log = log_class.new(owner_key => owner_record, user: current_user)
    @log.attach_document_from_signed_id(params[:signed_id], filename: params[:file_name]) if params[:signed_id].present?
    @log.save validate: false
    render js: 'location.reload()'
  end

  def edit_file
    render layout: false
  end

  def update_file
    assign_owner_ivar(@log.public_send(owner_key))
    @log.attach_document_from_signed_id(params[:signed_id], filename: params[:file_name]) if params[:signed_id].present?
    @flag = @log.save validate: false
  end

  def apply
    render layout: false
  end

  def do_apply
    assign_owner_ivar(@log.public_send(owner_key))
    begin
      # 保持原行为：update 校验失败时短路，不得调用 do_apply!。
      # 去掉这个分支会让校验失败的申请也显示"申请成功"——AASM 的
      # whiny_persistence 默认 false，持久化失败只静默返回 false。
      if @log.update log_permit
        @log.do_apply!
        @flag = true
      else
        @flag = false
      end
    rescue => e
      logger.warn "do_apply failed for #{@log.class}##{@log&.id}: #{e.class}: #{e.message}"
      @flag = false
    end
  end

  def show_version
    @version = owner_record.versions.find_by id: params[:version_id]
    render layout: false
  end

  private

  def owner_key
    controller_name.singularize.to_sym
  end

  def log_class
    "#{controller_name.singularize.camelize}Log".constantize
  end

  # 视图仍用 @product / @instance / @technology，故保持同名实例变量
  def assign_owner_ivar(record)
    instance_variable_set("@#{owner_key}", record)
  end

  def owner_record
    instance_variable_get("@#{owner_key}")
  end

  def set_log
    @log = current_user.public_send("#{controller_name.singularize}_logs").find_by id: params[:id]
    redirect_to send("#{controller_name}_path"), alert: t('flash.not_found') unless @log.present?
  end

  def log_permit
    params.require("#{controller_name.singularize}_log").permit(:develop_id, :flow_id, :active_id)
  end
end
