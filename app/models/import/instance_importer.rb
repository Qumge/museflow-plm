class Import::InstanceImporter < ActiveImporter::Base
  imports Product
  imports Instance
  imports InstanceCategory
  transactional

  # Excel 表头解耦（P4 Task 2f）。表头文字本身是"用户上传 .xlsx 的表头
  # 契约"——翻译它等于让存量文件全部导入失败。真正的表头文案按 locale
  # 存在 config/import_columns.yml 里；下面的业务逻辑一律只认语言无关的
  # 规范字段名（level/code/name/norms/category），不管上传的文件实际用
  # 中文还是英文表头。
  COLUMN_LOCALES = YAML.load_file(Rails.root.join('config', 'import_columns.yml')).deep_symbolize_keys.freeze

  # 字段顺序即表格展示顺序。level/code/name 是内容必填项；norms/category
  # 内容选填——但和改造前一样，表头本身仍要求 5 列都出现（不校验内容，
  # 只校验表头行里有没有这一列）。
  FIELDS = %i[level code name norms category].freeze
  REQUIRED_CONTENT_FIELDS = %i[level code name].freeze

  # 表头文字（任一语言）=> 规范字段名，用于把上传文件实际的表头文字
  # 翻译成规范 key。
  HEADER_TITLE_TO_FIELD = COLUMN_LOCALES.each_with_object({}) do |(_locale, titles), lookup|
    titles.each { |field, title| lookup[title.to_s] = field }
  end.freeze

  def self.title_for(field, locale = :zh)
    COLUMN_LOCALES.fetch(locale).fetch(field)
  end

  on :import_started do
    @row_count = 2
    @models = {}
    logger.info "开始导入物料信息...."
  end

  fetch_model do
    raise "第#{row_count}行 物料代码不存在。" unless row[:code].present?
    instance = Instance.find_or_initialize_by instance_no: row[:code]
    instance
  end

  on :row_processing do
    instance = model
    instance.user = params[:user]
    raise "第#{row_count}行 层级不存在。" unless row[:level].present?
    depth = row[:level].to_s.gsub('.', '').to_i
    if depth == 1
      instance.parent = nil
    else
      parent = @models[(depth - 1).to_s]
      if parent.present?
        instance.parent = parent
      else
        raise "第#{row_count}行 找不到上一层级。"
      end
    end

    raise "第#{row_count}行 物料名称不存在。" unless row[:name].present?
    instance.name = row[:name]

    instance.norms = row[:norms]

    if row[:category].present?
      instance_category = InstanceCategory.find_by(code: row[:category])
      if instance_category.present?
        instance.instance_category = instance_category
      else
        raise "第#{row_count}行 物料属性不存在。"
      end
    end

    instance.save
    @models[depth.to_s] = instance
  end

  on :row_processed do
    @row_count += 1
  end

  on :row_error do |e|
    logger.error e.message
  end

  on :import_failed do |exception|
    logger.error exception.message
  end

  on :import_finished do
    logger.info "#{@row_count} lines Data imported successfully!"
  end

  private

  def logger
    Logger.new "log/instance_import.log"
  end

  # -- 覆盖 ActiveImporter::Base 里两个依赖表头文字的私有方法 --
  #
  # 父类默认实现（active_importer gem）用 `column` DSL 声明的固定文字去
  # 匹配表头行、再原样把表头文字当 hash key。我们不用 `column` DSL 声明
  # 具体文案（那样就退回了"表头文字硬编码"），而是自己判断：某一行是否
  # 完整匹配 COLUMN_LOCALES 里任一整套语言的表头文字；找到后把该语言的
  # 表头文字统一翻译成规范字段名，业务逻辑就能用语言无关的 row[:code]
  # 这样的 key 读数据，不管用户上传的文件是中文表头还是英文表头。

  def find_header_index
    (1..@book.last_row).each do |index|
      cells = @book.row(index).map { |cell| cell.to_s.strip }
      matched_locale = COLUMN_LOCALES.values.any? do |titles|
        FIELDS.all? { |field| cells.include?(titles[field].to_s) }
      end
      return index if matched_locale
    end
    nil
  end

  def row_to_hash(row)
    hash = {}
    row.each_with_index do |value, index|
      field = HEADER_TITLE_TO_FIELD[@header[index]]
      hash[field] = value if field
    end
    hash
  end
end
