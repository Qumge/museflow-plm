# == Schema Information
#
# Table name: resources
#
#  id         :integer          not null, primary key
#  action     :string(255)
#  target     :string(255)
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Resource < ApplicationRecord
  has_and_belongs_to_many :roles, join_table: 'role_resources'

  MANIFEST_PATH = Rails.root.join('config', 'resources.yml')

  # config/resources.yml 是本应用权限的唯一事实来源。
  # 数据库中的 resources 行只有出现在该清单里才被授予。
  def self.manifest
    @manifest ||= YAML.load_file(MANIFEST_PATH).freeze
  end

  def self.permitted?(action, target)
    manifest.fetch(target.to_s, {}).key?(action.to_s)
  end

  def self.load!
    manifest.each do |target, value|
      value.each do |action, name|
        # (action, target) 是语言无关的查找键；name 是可更新的显示属性，
        # 翻译改名后重跑 load! 不应产生新行（见 P4 Task 2a）。
        Resource.find_or_create_by(action: action, target: target).update(name: name)
      end
    end
  end
end
