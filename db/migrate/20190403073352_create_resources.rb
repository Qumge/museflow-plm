class CreateResources < ActiveRecord::Migration[4.2]
  def change
    create_table :resources do |t|
      t.string :action
      t.string :target
      t.string :name
      t.timestamps null: false
    end
  end
end
