class AddColumnToInstances < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :instance_category_id, :integer
  end
end
