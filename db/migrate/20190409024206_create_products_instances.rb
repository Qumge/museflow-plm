class CreateProductsInstances < ActiveRecord::Migration[4.2]
  def change
    create_table :products_instances do |t|
      t.integer :product_id
      t.integer :instance_id
      t.timestamps null: false
    end
  end
end
