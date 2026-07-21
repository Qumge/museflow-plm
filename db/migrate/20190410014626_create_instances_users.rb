class CreateInstancesUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :instances_users do |t|
      t.integer :instance_id
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
