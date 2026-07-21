class Technology < ApplicationRecord
  include FileConcern
  has_paper_trail versions: {
      scope: -> { order("id desc") }
  }
  has_many :notices, -> {where(model_type: 'Technology')}, class_name: 'Notice', foreign_key: :model_id
  has_many :instances
  has_many :products
  has_many :technology_logs
  belongs_to :user
  belongs_to :last_user, foreign_key: :last_user_id, class_name: 'User'
  belongs_to :file_user, foreign_key: :file_user_id, class_name: 'User'
  validates_uniqueness_of :name, :no
  validates_presence_of :name, :no
  #has_many :technology_instances, dependent: :destroy

  def display_number
    no
  end

  def view_logs user
    if user.has_technology_log_resource?
      self.technology_logs
    else
      self.technology_logs.where(user: user)
    end
  end

  def get_model_name
    I18n.t('activerecord.models.technology')
  end


  class << self
    def search_conn params
      technologies = Technology.joins(:user).all
      if params[:table_search].present?
        technologies = technologies.where('technologies.no like ? or technologies.name like ? or users.name like ?',
                                    "%#{params[:table_search]}%", "%#{params[:table_search]}%", "%#{params[:table_search]}%")
      end
      technologies
    end

    def get_model_name
      I18n.t('activerecord.models.technology')
    end
  end

end
