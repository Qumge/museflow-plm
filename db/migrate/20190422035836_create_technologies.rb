class CreateTechnologies < ActiveRecord::Migration[4.2]
  def change
    create_table :technologies do |t|
      t.integer :user_id
      t.string :no
      t.string :name
      t.datetime :valid_at
      t.text :desc
      t.string :file_name
      t.string :file_path
      t.timestamps null: false
    end
  end
end
