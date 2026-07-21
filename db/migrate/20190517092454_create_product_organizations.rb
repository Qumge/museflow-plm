class CreateProductOrganizations < ActiveRecord::Migration[4.2]
  def change
    create_table :product_organizations do |t|
      t.integer :product_id
      t.integer :organization_id
      t.timestamps null: false
    end
  end
end
