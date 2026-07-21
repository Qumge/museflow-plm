class RemoveStlColumns < ActiveRecord::Migration[7.0]
  TABLES = %i[products instances technologies product_logs instance_logs technology_logs].freeze

  def change
    TABLES.each do |table|
      remove_column table, :stl_done, :boolean, default: false
      remove_column table, :stl_code, :string
      remove_column table, :last_stl_time, :datetime
    end
  end
end
