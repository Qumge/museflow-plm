class CreateProducts < ActiveRecord::Migration[4.2]
  def change
    create_table :products do |t|
      t.integer :category_id
      t.string :name
      t.string :product_no
      t.string :color
      t.string :norms
      t.string :file_name
      t.string :file_path
      t.text :desc
      t.integer :user_id
      t.integer :last_user_id
      t.timestamps null: false
    end
  end
end
