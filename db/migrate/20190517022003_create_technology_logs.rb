class CreateTechnologyLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :technology_logs do |t|
      t.integer :product_id
      t.string :file_name
      t.string :file_path
      t.integer :user_id
      t.string :status
      t.integer :develop_id
      t.integer :flow_id
      t.integer :active_id
      t.timestamps null: false
    end
  end
end
