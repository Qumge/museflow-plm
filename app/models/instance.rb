class Instance < ApplicationRecord
  include FileConcern
  has_paper_trail versions: {
      scope: -> { order("id desc") }
  }
  has_ancestry

  belongs_to :user
  belongs_to :last_user, foreign_key: :last_user_id, class_name: 'User'
  belongs_to :file_user, foreign_key: :file_user_id, class_name: 'User'
  belongs_to :instance_category
  belongs_to :technology

  has_many :instance_logs
  has_many :products_instances, dependent: :destroy
  has_many :technology_instances, dependent: :destroy
  has_many :notices, -> {where(model_type: 'Instance')}, class_name: 'Notice', foreign_key: :model_id

  has_and_belongs_to_many :products, join_table: 'products_instances'
  has_and_belongs_to_many :users, join_table: 'instances_users'
  has_and_belongs_to_many :organizations, join_table: 'instance_organizations'
  has_and_belongs_to_many :technologies, join_table: 'technology_instances'

  validates_presence_of :name, :instance_no
  validates_uniqueness_of :name, :instance_no



  def display_number
    instance_no
  end

  def view_logs user
    if user.has_instance_log_resource?
      self.instance_logs
    else
      self.instance_logs.where(user: user)
    end
  end

  def get_model_name
    I18n.t('activerecord.models.instance')
  end

  # def technology
  #   technologies.order('valid_at desc, updated_at desc').first
  # end

  class << self
    def search_conn params
      instances = Instance.joins(:user).all
      if params[:table_search].present?
        instances = instances.where('instances.instance_no like ? or instances.name like ? or instances.norms like ? or users.name like ?',
                                  "%#{params[:table_search]}%", "%#{params[:table_search]}%", "%#{params[:table_search]}%",
                                  "%#{params[:table_search]}%")
      end
      instances
    end

    def get_model_name
      I18n.t('activerecord.models.instance')
    end
  end
end
