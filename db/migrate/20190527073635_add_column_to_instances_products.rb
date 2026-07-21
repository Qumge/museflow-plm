class AddColumnToInstancesProducts < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :stl_done, :boolean, default: false
    add_column :instances, :stl_code, :string
    add_column :instances, :last_stl_time, :datetime

    add_column :instance_logs, :stl_done, :boolean, default: false
    add_column :instance_logs, :stl_code, :string
    add_column :instance_logs, :last_stl_time, :datetime

    add_column :products, :stl_done, :boolean, default: false
    add_column :products, :stl_code, :string
    add_column :products, :last_stl_time, :datetime

    add_column :product_logs, :stl_done, :boolean, default: false
    add_column :product_logs, :stl_code, :string
    add_column :product_logs, :last_stl_time, :datetime

    add_column :technologies, :stl_done, :boolean, default: false
    add_column :technologies, :stl_code, :string
    add_column :technologies, :last_stl_time, :datetime

    add_column :technology_logs, :stl_done, :boolean, default: false
    add_column :technology_logs, :stl_code, :string
    add_column :technology_logs, :last_stl_time, :datetime
  end
end
