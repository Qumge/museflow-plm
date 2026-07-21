require 'test_helper'
require 'csv'
require 'tmpdir'

# P4 Task 2f。
#
# Import::InstanceImporter 的 5 个 `column` 声明曾直接写死中文表头文字
# （'层级'/'物料代码'/'物料名称'/'规格型号'/'物料属性'），逐格取值也用
# `row['物料代码']` 这样的中文字面量做 key。这是"用户上传 .xlsx 的表头
# 契约"——翻译表头文案会让存量文件全部导入失败，而且是静默失败（表头
# 校验直接报错，不会误导入错数据，但从用户角度看是"文件突然坏了"）。
#
# 改造后表头文案迁到 config/import_columns.yml，按 locale 分组，importer
# 内部只认语言无关的规范字段（level/code/name/norms/category）；中文表头
# 与英文表头都被接受，但不支持中英混填在同一个表头行里。
#
# `InstanceCategory.find_by name: row['物料属性']` 曾把"Excel 单元格值"
# 和"数据库显示名"耦合在一起；改造后 InstanceCategory 新增语言无关的
# code 列，导入按 code 查找，name 退为纯展示。
class Import::InstanceImporterTest < ActiveSupport::TestCase
  def setup
    @user = create_user(login: 'importer_tester')
    @tmp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir)
  end

  test "imports a two-level BOM using the Chinese header set (legacy files keep working)" do
    category = InstanceCategory.create!(name: '标准件', code: '标准件')
    path = write_csv('zh.csv', [
      %w[层级 物料代码 物料名称 规格型号 物料属性],
      ['1', 'C-100', '轴', 'M6', ''],
      ['2', 'C-101', '螺栓', 'M6x20', '标准件']
    ])

    Import::InstanceImporter.import(path, params: { user: @user })

    parent = Instance.find_by!(instance_no: 'C-100')
    child = Instance.find_by!(instance_no: 'C-101')
    assert_equal '轴', parent.name
    assert_nil parent.parent
    assert_equal parent.id, child.parent_id
    assert_equal category, child.instance_category
  end

  test "imports the same BOM shape using the English header set" do
    category = InstanceCategory.create!(name: '标准件', code: '标准件')
    path = write_csv('en.csv', [
      ['Level', 'Material Code', 'Material Name', 'Specification', 'Material Category'],
      ['1', 'C-200', 'Shaft', 'M6', ''],
      ['2', 'C-201', 'Bolt', 'M6x20', '标准件']
    ])

    Import::InstanceImporter.import(path, params: { user: @user })

    parent = Instance.find_by!(instance_no: 'C-200')
    child = Instance.find_by!(instance_no: 'C-201')
    assert_equal 'Shaft', parent.name
    assert_nil parent.parent
    assert_equal parent.id, child.parent_id
    assert_equal category, child.instance_category
  end

  test "resolves InstanceCategory by the language-independent code, not by its (possibly translated) display name" do
    # name 已经和 code 不一样了（模拟 code 加进来之后、name 后续被翻译的
    # 场景）——Excel 单元格里的值必须仍然按 code 匹配，而不是按当前的
    # 展示名匹配。
    category = InstanceCategory.create!(name: 'Standard Part (translated display name)', code: '标准件')
    path = write_csv('code_lookup.csv', [
      %w[层级 物料代码 物料名称 规格型号 物料属性],
      ['1', 'C-300', '螺母', 'M6', '标准件']
    ])

    Import::InstanceImporter.import(path, params: { user: @user })

    instance = Instance.find_by!(instance_no: 'C-300')
    assert_equal category, instance.instance_category
  end

  test "does not fall back to matching InstanceCategory by display name" do
    # code 和 name 现在是两个独立的值；Excel 单元格值只匹配 name 时必须
    # 仍然找不到——否则说明查找又退回了旧的双重耦合。
    InstanceCategory.create!(name: '标准件', code: 'STD')
    path = write_csv('name_mismatch.csv', [
      %w[层级 物料代码 物料名称 规格型号 物料属性],
      ['1', 'C-400', '垫片', 'M6', '标准件']
    ])

    error = assert_raises(RuntimeError) do
      Import::InstanceImporter.import(path, params: { user: @user })
    end
    assert_match '物料属性不存在', error.message
  end

  test "raises a clear error when a required header column is missing from any known locale" do
    # 表头结构契约本身没有变松：还是要求 5 列都出现在表头行里，只是
    # 现在接受中文或英文两套文字中的任意一套完整集合，而不是只认死中文。
    path = write_csv('missing_column.csv', [
      %w[层级 物料代码 物料名称 规格型号],
      ['1', 'C-500', '螺钉', 'M6']
    ])

    error = assert_raises(RuntimeError) do
      Import::InstanceImporter.import(path, params: { user: @user })
    end
    assert_match 'does not contain all the expected columns', error.message
  end

  test "rejects a header row that mixes Chinese and English column titles" do
    path = write_csv('mixed_header.csv', [
      ['层级', 'Material Code', '物料名称', '规格型号', '物料属性'],
      ['1', 'C-600', '弹簧', 'M6', '']
    ])

    assert_raises(RuntimeError) do
      Import::InstanceImporter.import(path, params: { user: @user })
    end
  end

  private

  def write_csv(filename, rows)
    path = File.join(@tmp_dir, filename)
    CSV.open(path, 'w') { |csv| rows.each { |row| csv << row } }
    path
  end
end
