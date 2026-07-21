class NoticesController < ApplicationController
  before_action :set_user_notice, only: [:show, :reply, :do_reply]
  before_action :set_notice, only: [:edit, :update, :show_notice]

  def index
    @receive_notices = current_user.user_notices.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
    @send_notices = current_user.send_notices.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
  end

  def receives
    @receive_notices = current_user.user_notices.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
  end

  def sends
    @send_notices = current_user.send_notices.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
  end

  def new
    @notice = Notice.new
    render layout: false
  end

  def create
    @notice = current_user.send_notices.new
    if params[:signed_id].present?
      file = Attachment.new file_name: params[:file_name], model_type: 'Notice'
      file.attach_document_from_signed_id(params[:signed_id])
      @notice.file = file
    end
    @flag = @notice.update notice_permit
  end

  def show
    @user_notice.update readed: true unless @user_notice.readed
  end

  def edit

  end

  def update
    if params[:signed_id].present?
      file = Attachment.new file_name: params[:file_name], model_type: 'Notice'
      file.attach_document_from_signed_id(params[:signed_id])
      @notice.file = file
    end
    @flag = @notice.update notice_permit
  end

  def reply
    render layout: false
  end

  def do_reply
    @user_notice.update reply: params[:user_notice][:reply], replied_at: DateTime.now, replied: true
  end

  private
  def notice_permit
    params.require(:notice).permit(:title, :content, :model_val,:need_reply, user_ids: [])
  end

  def set_user_notice
    @user_notice = current_user.user_notices.find_by id: params[:id]
    redirect_to receives_notices_path, alert: t('flash.not_found') unless @user_notice.present?
  end

  def set_notice
    @notice = current_user.send_notices.find_by id: params[:id]
    redirect_to send_notices_path, alert: t('flash.not_found') unless @notice.present?
  end




end
