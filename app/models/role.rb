# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  desc       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Role < ApplicationRecord
  has_many :role_resources
  has_and_belongs_to_many :resources, join_table: 'role_resources'
  # desc 是语言无关的查找键（user.rb#has_role? / ability.rb / rails_admin.rb
  # 全部按 desc 比对，P4 Task 2e 已确认），不能改；这里的中文 value 只会在
  # Role.load! 建行时一次性写入 roles.name 列，此后不再回写（见 #load!），
  # 所以不能指望 name 列跟着 locale 切换——展示一律走 #display_name。
  ROLES = {super_admin: '超级管理员', develop_manager: '研发管理', developer: '研发', processer: '流程管理'}

  class << self
    def load!
      ROLES.each do |key, value|
        Role.create name: value, desc: key unless Role.find_by(desc: key).present?
      end
    end
  end

  # roles.name 只在建行那一刻被写入（见 .load!），之后永远不变，所以不能
  # 用它做界面展示——否则语言切换对角色名不生效（这正是本次发现的缺口）。
  # 和 LogWorkflow#get_status / Matter#get_status 一样，翻译结果每次调用时
  # 现取，ROLES 的中文字面量只作为未翻译时的兜底默认值。
  def display_name
    return name if desc.blank?

    I18n.t(desc.to_sym, scope: 'statuses.role', default: ROLES[desc.to_sym] || name)
  end
end
