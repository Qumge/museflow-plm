class InstancesController < ApplicationController
  include Auditable
  include FileAttachable
  before_action :set_instance, only: [:show, :edit, :update, :destroy, :show_version, :upload_file, :do_upload_file]
  def index
    @instances = Instance.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
  end

  def new
    @instance = Instance.new
    render layout: false
  end

  def create
    @instance = Instance.new
    @instance.user = current_user
    @flag = @instance.update instance_permit
  end

  def show

  end

  def edit
    render layout: false
  end

  def update
    @flag = @instance.update instance_permit
  end

  def destroy
    if @instance.destroy
      redirect_to instances_path, notice: t('flash.delete_success')
    else
      redirect_to instances_path, alert: t('flash.delete_failed')
    end
  end

  def import
    render layout: false
  end

  def do_import
    begin
      Import::InstanceImporter.import(params[:file].path, params: {user: current_user}) if params[:file]
      redirect_to instances_path, notice: t('flash.import_success')
    rescue => e
      redirect_to instances_path, alert: e.message
    end
  end

  private

  def instance_permit
    params.require('instance').permit(:instance_no, :name, :norms, :parent_id,  :desc, :instance_category_id, :technology_id, user_ids: [], product_ids: [], organization_ids: [])
  end

  def set_instance
    @instance = Instance.find_by id: params[:id]
    redirect_to instances_path, alert: t('flash.not_found') unless @instance.present?
  end
end
