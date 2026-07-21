class CreateUserNotices < ActiveRecord::Migration[4.2]
  def change
    create_table :user_notices do |t|
      t.integer :user_id
      t.integer :notice_id
      t.text :reply
      t.boolean :readed
      t.boolean :replied
      t.datetime :replied_at
      t.timestamps null: false
    end
  end
end
