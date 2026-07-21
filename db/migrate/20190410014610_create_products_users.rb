class CreateProductsUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :products_users do |t|
      t.integer :product_id
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
