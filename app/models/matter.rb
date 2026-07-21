class Matter < ApplicationRecord
  include FileConcern
  has_paper_trail only: [:file_path, :file_name], versions: {
      scope: -> { order("id desc") }
  }
  STATUS = {circulation: '流转中', countersign: '会签中', active: '已完成'}
  has_many :notices, -> {where(model_type: 'Matter')}, class_name: 'Notice', foreign_key: :model_id
  belongs_to :user
  belongs_to :file_user, foreign_key: :file_user_id, class_name: 'User'
  belongs_to :countersign_user, foreign_key: :countersign_user_id, class_name: 'User'
  validates_presence_of :name
  has_and_belongs_to_many :users, join_table: 'user_matters'
  has_many :user_matters
  

  def display_number
    nil
  end

  def user_matter user
    self.user_matters.where(user: user).first
  end

  def get_status
    # See LogWorkflow#get_status for why this resolves via I18n.t at call time
    # rather than baking the translation into the STATUS constant itself.
    I18n.t(self.status.to_sym, scope: 'statuses.matter', default: Matter::STATUS[self.status.to_sym])
  end

  def check_agree
    flag = true
    self.user_matters.each do |user_matter|
      flag = flag && user_matter.agree
    end
    self.update agree: true, status: :active if flag
  end



  class << self
    def search_conn params
      matters = Matter.joins(:user).all
      if params[:table_search].present?
        matters = matters.where('matters.name like ? or users.name like ?',
                                  "%#{params[:table_search]}%", "%#{params[:table_search]}%")
      end
      matters
    end

    def get_model_name
      I18n.t('activerecord.models.matter')
    end
  end
end
