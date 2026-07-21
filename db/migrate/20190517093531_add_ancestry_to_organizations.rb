class AddAncestryToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :ancestry, :string
    add_index :organizations, :ancestry
  end
end
