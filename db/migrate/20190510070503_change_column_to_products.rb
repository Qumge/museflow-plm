class ChangeColumnToProducts < ActiveRecord::Migration[4.2]
  def up
    remove_column :products, :active_at
    add_column :products, :active_at, :datetime
  end

  def down
    remove_column :products, :active_at
    add_column :products, :active_at, :integer
  end
end
