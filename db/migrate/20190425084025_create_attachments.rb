class CreateAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :attachments do |t|
      t.integer :model_id
      t.string :model_type
      t.string :path
      t.string :file_name
      t.timestamps null: false
    end
  end
end
