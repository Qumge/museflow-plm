class ChangeColumnForInstances < ActiveRecord::Migration[4.2]
  def up
    remove_column :instances, :file_user_id
    add_column :instances, :file_user_id, :integer
  end

  def down
    remove_column :instances, :file_user_id
    add_column :instances, :file_user_id, :timestamp
  end
end
