class ProductsController < ApplicationController
  include Auditable
  include FileAttachable
  before_action :set_product, only: [:show, :edit, :update, :destroy, :show_version, :upload_file, :do_upload_file]
  def index
    @products = Product.search_conn(params).order('updated_at desc').page(params[:page]).per(Settings.per_page)
  end

  def new
    @product = Product.new
    render layout: false
  end

  def create
    @product = Product.new
    @product.user = current_user
    @flag = @product.update product_permit
  end

  def show

  end

  def edit
    render layout: false
  end

  def update
    @flag = @product.update product_permit
  end

  def destroy
    if @product.destroy
      redirect_to products_path, notice: t('flash.delete_success')
    else
      redirect_to products_path, alert: t('flash.delete_failed')
    end
  end

  def import
    render layout: false
  end

  def do_import
    if params[:develop_id].present? && params[:flow_id].present? && params[:active_id].present? && params[:file].present?
      FileUtils.mkdir_p ZipFile::ZIP_DIR
      File.open(File.join(ZipFile::ZIP_DIR, params[:file].original_filename), "wb") do |file|
        file.write params[:file].read
      end
      ZipJob.perform_later params[:file].original_filename, params[:develop_id], params[:flow_id], params[:active_id], current_user
      redirect_to products_path, notice: t('flash.upload_processing')
    else
      redirect_to products_path, alert: t('flash.incomplete_data')
    end
  end

  private

  def product_permit
    params.require('product').permit(:category_id,:product_no, :name, :norms, :desc, :technology_id,instance_ids: [], user_ids: [], organization_ids: [])
  end

  def set_product
    @product = Product.find_by id: params[:id]
    redirect_to products_path, alert: t('flash.not_found') unless @product.present?
  end

end
