class CreateInstanceOrganizations < ActiveRecord::Migration[4.2]
  def change
    create_table :instance_organizations do |t|
      t.integer :instance_id
      t.integer :organization_id
      t.timestamps null: false
    end
  end
end
