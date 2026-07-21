# frozen_string_literal: true

# FileConcern#download_url / #preview_url（以及 Attachment#preview_url）在模型层
# 调用 rails_blob_url 生成绝对 URL —— office/dwg 外部预览服务
# （view.officeapps.live.com、sharecad.org，见
# app/assets/javascripts/application.js#show_file）需要一个公网可达的绝对地址，
# 相对路径对它们没有意义。模型方法没有 request 上下文，Rails 不能像在
# view/controller 里那样自动从当前请求推断 host，必须显式配置
# default_url_options，否则会抛 ActionController::UrlGenerationError: Missing host。
#
# 生产环境请通过 APP_HOST（以及可选的 APP_PORT / APP_PROTOCOL）设置真实域名；
# 未设置时退回 localhost（开发环境默认带上 :3000，跟
# config.action_mailer.default_url_options 的既有约定保持一致），
# 保证应用不会因为漏配而在这类调用上直接崩溃——FileConcern#download_url
# 内部还包了一层 rescue 兜底，双重保险，不会重演 P0 修过的
# `qiniu_domain + '/' + file_path` 在 domain 为 nil 时崩溃的问题。
Rails.application.routes.default_url_options[:host] = ENV.fetch('APP_HOST', 'localhost')

default_port = ENV['APP_PORT'] || (Rails.env.development? ? '3000' : nil)
Rails.application.routes.default_url_options[:port] = default_port if default_port.present?

Rails.application.routes.default_url_options[:protocol] =
  ENV.fetch('APP_PROTOCOL', Rails.env.production? ? 'https' : 'http')
