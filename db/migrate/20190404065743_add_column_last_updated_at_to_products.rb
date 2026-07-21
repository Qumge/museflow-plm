class AddColumnLastUpdatedAtToProducts < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :last_updated_at, :datetime
  end
end
