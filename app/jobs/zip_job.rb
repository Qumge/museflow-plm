class ZipJob < ActiveJob::Base
  queue_as :default

  def perform(zip_name, develop_id, flow_id, active_id, user)
    # Do somethin
    zip_files = ZipFile.new(zip_name: zip_name).unzip
    ZipUploadJob.perform_later zip_files, develop_id, flow_id, active_id, user
  end
end