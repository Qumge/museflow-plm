class CreateInstances < ActiveRecord::Migration[4.2]
  def change
    create_table :instances do |t|
      t.string :name
      t.string :instance_no
      t.string :color
      t.string :norms
      t.string :file_name
      t.string :file_path
      t.text :desc
      t.integer :user_id
      t.integer :last_user_id
      t.datetime :last_updated_at
      t.timestamps null: false
    end
  end
end
