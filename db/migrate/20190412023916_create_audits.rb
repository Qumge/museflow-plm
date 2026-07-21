class CreateAudits < ActiveRecord::Migration[4.2]
  def change
    create_table :audits do |t|
      t.integer :model_id
      t.string :model_type
      t.string :from_status
      t.string :to_status
      t.string :content
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
