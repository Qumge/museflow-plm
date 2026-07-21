# == Schema Information
#
# Table name: products
#
#  id           :integer          not null, primary key
#  category_id  :integer
#  name         :string(255)
#  product_no   :string(255)
#  color        :string(255)
#  norms        :string(255)
#  file_name    :string(255)
#  file_path    :string(255)
#  desc         :text(65535)
#  user_id      :integer
#  last_user_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Product < ApplicationRecord
  include FileConcern
  has_paper_trail versions: {
      scope: -> { order("id desc") }
  }
  has_many :notices, -> {where(model_type: 'Product')}, class_name: 'Notice', foreign_key: :model_id
  belongs_to :user
  belongs_to :last_user, foreign_key: :last_user_id, class_name: 'User'
  belongs_to :file_user, foreign_key: :file_user_id, class_name: 'User'
  has_many :product_logs
  has_many :products_instances
  belongs_to :technology
  validates_presence_of :name, :product_no
  has_and_belongs_to_many :instances, join_table: 'products_instances'
  has_and_belongs_to_many :organizations, join_table: 'product_organizations'
  has_and_belongs_to_many :users, join_table: 'products_users'
  validates_uniqueness_of :name, :product_no



  def display_number
    product_no
  end

  def view_logs user
    if user.has_product_log_resource?
      self.product_logs
    else
      self.product_logs.where(user: user)
    end
  end

  def get_model_name
    I18n.t('activerecord.models.product')
  end

  class << self
    def search_conn params
      products = Product.joins(:user).all
      if params[:table_search].present?
        products = products.where('products.product_no like ? or products.name like ? or products.norms like ? or users.name like ?',
                                  "%#{params[:table_search]}%", "%#{params[:table_search]}%", "%#{params[:table_search]}%",
                                  "%#{params[:table_search]}%")
      end
      products
    end

    def get_model_name
      I18n.t('activerecord.models.product')
    end


    def format_files files, develop_id, flow_id, active_id, user
      logger = Logger.new 'log/zip_upload.log'
      logger.info "----start format  #{files}------"
      reg = /\((.+?)\)/
      files.each do |file_name|
        logger.info "----start attach #{file_name}------"
        file_path = File.join ZipFile::UNZIP_DIR, file_name
        next unless File.exist? file_path

        m = file_name.match(reg)
        if m.present?
          no = m[1]
          product = Product.find_by product_no: no
          if product.present?
            log = ProductLog.new product: product, user: user, status: :apply, apply_at: DateTime.now,
                                  develop_id: develop_id, flow_id: flow_id, active_id: active_id
          else
            instance = Instance.find_by instance_no: no
            if instance.present?
              log = InstanceLog.new instance: instance, user: user, status: :apply, apply_at: DateTime.now,
                                     develop_id: develop_id, flow_id: flow_id, active_id: active_id
            end
          end
          if log.present?
            # save 必须在 File.open 块内完成——ActiveStorage 的实际字节上传发生在
            # log.save 触发的 after_commit 回调里，不是 attach_document 那一刻。
            # 如果先关闭文件再 save，上传时读到的就是已关闭的 IO，直接抛
            # IOError: closed stream（本地实测验证过，不是理论推测）。
            File.open(file_path, 'rb') do |io|
              log.attach_document(io: io, filename: file_name)
              log.save
            end
            logger.info "---- attached #{file_name} to #{log.class}##{log.id}------"
          end
        end
        File.delete file_path
        logger.info "----end attach #{file_name}------"
      end
    end
  end

end
