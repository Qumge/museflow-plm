class MattersController < ApplicationController
  before_action :set_matter, only: [:show, :edit, :update, :destroy, :upload_file, :do_upload_file, :notices, :send_notice, :countersign, :agree]
  def index
    @matters = Matter.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
  end

  def new
    @matter = current_user.matters.new
    render layout: false
  end

  def create
    @matter = current_user.matters.new
    @flag = @matter.update matter_permit
  end

  def show

  end

  def edit
    render layout: false
  end

  def update
    @flag = @matter.update matter_permit
  end

  def destroy
    if @matter.destroy
      redirect_to matters_path, notice: t('flash.delete_success')
    else
      redirect_to matters_path, alert: t('flash.delete_failed')
    end
  end

  def upload_file
    render layout: false
  end

  def do_upload_file
    user_matter = UserMatter.find_by user: current_user, matter: @matter
    UserMatter.create user: current_user, matter: @matter unless user_matter.present?
    if params[:signed_id].present?
      # 用赋值而不是 attach(signed_id)：Matter 是已持久化且此刻无未保存改动的
      # 记录，Attached::One#attach 在这种情况下会在内部立即调用一次校验过的
      # save——那次 save 只会持久化 document 关联本身，file_path/file_name
      # 还没来得及一起写入，等下面这次 update 才真正落库 file_path/file_name，
      # 从而让 paper_trail（Matter 上 `only: [:file_path, :file_name]`）在这
      # 一次 update 里正确记一条版本，而不是被 update_columns 之类的写法绕过。
      @matter.document = params[:signed_id]
      @matter.update file_path: @matter.document.blob.key, file_name: params[:file_name],
                     file_user: current_user, last_update_at: DateTime.now
    else
      @matter.update file_user: current_user, last_update_at: DateTime.now
    end
    render js: 'location.reload()'
  end

  def notices
    #render layout: false
    render layout: false
  end

  def send_notice
    if params[:user_ids].present?
      params[:user_ids].each do|user_id|
        user = User.find_by id: user_id
        current_user.send_bom_notice user, @matter if user.present?
      end
    end
  end

  def agree
    user_matter = @matter.user_matter current_user
    user_matter.update agree: true if user_matter.present?
  end

  def countersign
    @matter.update countersign_user: current_user, countersign_at: DateTime.now, status: 'countersign'
    current_user.send_countersign_notice @matter.users, @matter
  end

  private
  def matter_permit
    params.require('matter').permit(:name, :desc)
  end

  def set_matter
    @matter = Matter.find_by id: params[:id]
    redirect_to matters_path, alert: t('flash.not_found') unless @matter.present?
  end
end
