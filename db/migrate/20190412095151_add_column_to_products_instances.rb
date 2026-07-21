class AddColumnToProductsInstances < ActiveRecord::Migration[4.2]
  def change
    add_column :products , :file_user_id, :integer
    add_column :products , :active_at, :integer
    add_column :instances , :file_user_id, :datetime
    add_column :instances , :active_at, :datetime
  end
end
