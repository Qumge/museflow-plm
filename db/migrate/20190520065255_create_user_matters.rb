class CreateUserMatters < ActiveRecord::Migration[4.2]
  def change
    create_table :user_matters do |t|
      t.integer :user_id
      t.integer :matter_id
      t.boolean :agree
      t.timestamps null: false
    end
  end
end
