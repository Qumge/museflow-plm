class CreateMatters < ActiveRecord::Migration[4.2]
  def change
    create_table :matters do |t|
      t.string :name
      t.text :desc
      t.integer :user_id
      t.integer :file_user_id
      t.datetime :last_update_at
      t.string :file_path
      t.string :file_name
      t.boolean :agree
      t.timestamps null: false
    end
  end
end
