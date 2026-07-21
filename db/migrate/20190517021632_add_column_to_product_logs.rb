class AddColumnToProductLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :product_logs, :develop_id, :integer
    add_column :product_logs, :flow_id, :integer
    add_column :product_logs, :active_id, :integer
    add_column :products, :technology_id, :integer
    add_column :instances, :technology_id, :integer
    add_column :instance_logs, :develop_id, :integer
    add_column :instance_logs, :flow_id, :integer
    add_column :instance_logs, :active_id, :integer
  end
end
