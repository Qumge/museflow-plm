class UserNotice < ApplicationRecord
  belongs_to :notice
  belongs_to :user

  # 语言无关的状态过滤枚举（P4 Task 2d）。下拉筛选控件的显示文案可以被
  # 翻译，但传给 search_conn 的 params[:status] 必须是这四个英文值之一，
  # 与 UI 文案完全解耦。
  STATUSES = %w[unread read unreplied replied].freeze

  class << self
    def search_conn params
      case params[:status]
      when 'unread'
        self.joins(notice: :user).where('readed is null or readed = false')
      when 'read'
        self.joins(notice: :user).where(readed: true)
      when 'unreplied'
        self.joins(notice: :user).where('notices.need_reply = true').where('replied is null or replied = false')
      when 'replied'
        self.joins(notice: :user).where('notices.need_reply = true').where(replied: true)
      else
        if params[:table_search].present?
          self.joins(notice: :user).where('users.name like ? or notices.title like ?', "%#{params[:table_search]}%", "%#{params[:table_search]}%")
        else
          self.all
        end
      end
    end
  end
end
