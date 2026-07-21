class Audit < ApplicationRecord
  belongs_to :user
  belongs_to :product_log, -> {where(model_type: 'ProductLog')}, foreign_key: :model_id
  belongs_to :instance_log, -> {where(model_type: 'InstanceLog')}, foreign_key: :model_id
  belongs_to :technology_log, -> {where(model_type: 'TechnologyLog')}, foreign_key: :model_id
end
