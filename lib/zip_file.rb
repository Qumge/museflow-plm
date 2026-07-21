require 'zip'
class ZipFile
  # 工作目录必须在 public/ 之外——public/zip 曾经无鉴权公网可读，导入原件
  # （可能含未审批的图纸）任何人都能直接下载。tmp/ 不由 Rails 对外提供服务。
  ZIP_DIR = Rails.root.join('tmp', 'imports').to_s
  UNZIP_DIR = Rails.root.join('tmp', 'imports', 'unzipped').to_s

  attr_accessor :zip_name, :zip_path

  #
  #
  def initialize args={}
    @zip_name = args[:zip_name]
    @zip_path = File.join ZIP_DIR, @zip_name
    @input_dir = UNZIP_DIR
  end


  def unzip
    FileUtils.mkdir_p @input_dir
    unzip_files = []
    Zip::File.open(@zip_path) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # Extract to file/directory/symlink
        #获取文件名
        file_name = entry.name.split('/').last
        # 空文件名标识为 文件夹  .开头标识隐藏文件
        next if entry.name.last == '/' || file_name.first == '.'
        begin
          logger.info "Extracting #{entry.name}"
          file_path = File.join @input_dir, file_name
          entry.extract file_path
          unzip_files << file_name
        rescue => e
          logger.info e.message
        end

        # Read into memory
        #content = entry.get_input_stream.read
      end
      # Find specific entry
      #entry = zip_file.glob('*.csv').first
      #puts entry.get_input_stream.read
    end
    unzip_files
  end

  def logger
    Logger.new 'log/unzip.log'
  end


end