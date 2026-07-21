# == Schema Information
#
# Table name: product_logs
#
#  id         :integer          not null, primary key
#  product_id :integer
#  file_name  :string(255)
#  file_path  :string(255)
#  user_id    :integer
#  status     :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProductLog < ApplicationRecord
  include LogWorkflow

  log_owner :product
end
