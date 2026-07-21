class TechnologiesController < ApplicationController
  include Auditable
  include FileAttachable
  before_action :set_technology, only: [:show, :edit, :update, :destroy, :show_version, :upload_file, :do_upload_file]
  def index
    @technologies = Technology.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
  end

  def new
    @technology = Technology.new
    render layout: false
  end

  def create
    @technology = Technology.new
    @technology.user = current_user
    @flag = @technology.update technology_permit
  end

  def show

  end

  def edit
    render layout: false
  end

  def update
    @flag = @technology.update technology_permit
  end

  def destroy
    if @technology.destroy
      redirect_to technologies_path, notice: t('flash.delete_success')
    else
      redirect_to technologies_path, alert: t('flash.delete_failed')
    end
  end

  private

  def technology_permit
    params.require('technology').permit(:no, :name, :valid_at, :desc, :technology_id, instance_ids: [], product_ids: [])
  end

  def set_technology
    @technology = Technology.find_by id: params[:id]
    redirect_to technologies_path, alert: t('flash.not_found') unless @technology.present?
  end

end
