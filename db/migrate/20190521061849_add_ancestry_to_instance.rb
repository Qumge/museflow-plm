class AddAncestryToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :ancestry, :string
    add_index :instances, :ancestry
  end
end
