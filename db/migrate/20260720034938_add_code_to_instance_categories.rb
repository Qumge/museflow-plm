class AddCodeToInstanceCategories < ActiveRecord::Migration[7.0]
  # P4 Task 2f：InstanceCategory.name 目前身兼两职——数据库显示名，
  # 也是 Excel 导入按物料属性单元格值反查记录的业务标识。翻译 name 会让
  # 存量 Excel 文件全部导入失败。这里加一列语言无关的 code 作为查找键，
  # name 退为纯显示；code 的初始值取当前 name（此刻两者字面相同），
  # 之后翻译 name 不会改动 code，保持导入行为不变。
  def up
    add_column :instance_categories, :code, :string
    execute 'UPDATE instance_categories SET code = name WHERE code IS NULL'
    add_index :instance_categories, :code
  end

  def down
    remove_index :instance_categories, :code
    remove_column :instance_categories, :code
  end
end
