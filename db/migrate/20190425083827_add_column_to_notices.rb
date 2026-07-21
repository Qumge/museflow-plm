class AddColumnToNotices < ActiveRecord::Migration[4.2]
  def change
    add_column :notices, :title, :string
    add_column :notices, :user_id, :integer
  end
end
