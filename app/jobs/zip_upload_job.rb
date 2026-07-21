class ZipUploadJob < ActiveJob::Base
  queue_as :default

  def perform(zip_files, develop_id, flow_id, active_id, user)
    # Do somethin
    Product.format_files zip_files, develop_id, flow_id, active_id, user
  end
end