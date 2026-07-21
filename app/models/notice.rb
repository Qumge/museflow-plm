class Notice < ApplicationRecord
  attr_accessor :model_val
  has_many :user_notices
  belongs_to :user
  has_and_belongs_to_many :users, join_table: 'user_notices'
  scope :initiative_notices, ->{where(model_type: 'User')}
  has_one :file, -> {where(model_type: 'Notice')}, class_name: 'Attachment', foreign_key: :model_id
  validates_presence_of :title, :content
  before_save :check_model
  belongs_to :product, class_name: 'Product', foreign_key: :model_id
  belongs_to :instance, class_name: 'Instance', foreign_key: :model_id
  belongs_to :technology, class_name: 'Technology', foreign_key: :model_id
  belongs_to :matter, class_name: 'Matter', foreign_key: :model_id


  class << self
    def search_conn params
      if params[:table_search].present?
        self.joins(:user).where('users.name like ? or notices.content like ?', "%#{params[:table_search]}%", "%#{params[:table_search]}%")
      else
        self.all
      end
    end
  end

  def user_notice user
    user_notices.find_by user: user
  end

  def replied_users
    user_notices.where(replied: true)
  end

  def readed_users
    user_notices.where(readed: true)
  end

  def sub_content
    content.size > 20 ? "#{content[0, 19]}..." : content
  end

  def check_model
    if self.model_val.present?
      val = model_val.split('_')
      self.model_type =  val[0]
      self.model_id =  val[1]
    end
  end

  def get_model
    self.send self.model_type.downcase if model_type.present?
  end




end
