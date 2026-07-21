class AddColumnActiveAtToProductLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :product_logs, :active_at, :datetime
  end
end
