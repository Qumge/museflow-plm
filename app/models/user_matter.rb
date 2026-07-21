class UserMatter < ApplicationRecord
  belongs_to :user
  belongs_to :matter
  after_update :check_agree

  def format_agree
    # See LogWorkflow#get_status / Matter#get_status for why this resolves
    # via I18n.t at call time rather than baking the translation into a
    # frozen constant (P4 Task 2c made this method pure display).
    key = case self.agree
          when true
            :confirmed
          when false
            :failed
          else
            :pending
          end
    I18n.t(key, scope: 'statuses.user_matter')
  end

  def check_agree
    if self.agree
      self.matter.check_agree
    end
  end
end
