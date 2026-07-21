class CreateInstanceCategories < ActiveRecord::Migration[4.2]
  def change
    create_table :instance_categories do |t|
      t.string :name
      t.text :desc
      t.timestamps null: false
    end
  end
end
