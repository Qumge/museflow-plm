class CreateTechnologyInstances < ActiveRecord::Migration[4.2]
  def change
    create_table :technology_instances do |t|
      t.integer :technology_id
      t.integer :instance_id
      t.timestamps null: false
    end
  end
end
