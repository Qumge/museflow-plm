class AddColumnToTechnologies < ActiveRecord::Migration[4.2]
  def change
    add_column :technologies, :last_user_id, :integer
    add_column :technologies, :file_user_id, :integer
  end
end
