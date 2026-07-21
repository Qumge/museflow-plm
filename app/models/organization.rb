class Organization < ApplicationRecord
  has_ancestry
  has_and_belongs_to_many :instances, join_table: 'instance_organizations'
  has_and_belongs_to_many :products, join_table: 'product_organizations'
end
