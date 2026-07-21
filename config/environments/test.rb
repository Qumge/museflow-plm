require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false

  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test

  # 测试不应向真实 Redis 入队：config/application.rb 全局设置的 :sidekiq 适配器
  # 会让后台任务在测试环境下真实连接 Redis，既依赖外部服务，
  # 又会污染开发者本机队列。
  config.active_job.queue_adapter = :test

  config.active_support.deprecation = :stderr

  config.active_storage.service = :test
end
