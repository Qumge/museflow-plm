class RenameColumnToTechnologyLogs < ActiveRecord::Migration[4.2]
  def change
    rename_column :technology_logs, :product_id, :technology_id
    add_column :technologies, :active_at, :datetime
    add_column :technology_logs, :active_at, :datetime
    add_column :technology_logs, :apply_at, :datetime
  end
end
