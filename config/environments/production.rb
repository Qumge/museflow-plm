require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = true

  config.assets.compile = false
  config.assets.digest = true

  config.log_level = :debug

  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false

  # 默认本地磁盘仅为使应用开箱可启动。
  # ⚠️ Render 一类 PaaS 的文件系统是临时的——生产务必设 STORAGE_SERVICE=r2，
  # 否则每次部署已上传的文件会静默丢失。
  config.active_storage.service = ENV.fetch("STORAGE_SERVICE", "local").to_sym

  exception_recipients = ENV.fetch('EXCEPTION_RECIPIENTS', '').split(',').map(&:strip).reject(&:empty?)

  if exception_recipients.any?
    config.middleware.use ExceptionNotification::Rack,
                          :email => {
                              :email_prefix => "[MuseFlow]",
                              :sender_address => %{"系统异常" <#{ENV.fetch('EXCEPTION_SENDER_ADDRESS', 'noreply@example.com')}>},
                              :exception_recipients => exception_recipients
                          }
  end
end
