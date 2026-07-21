class AddColumnToLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :product_logs, :apply_at, :datetime
    add_column :instance_logs, :apply_at, :datetime
  end
end
