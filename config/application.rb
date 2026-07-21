require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Museflow
  class Application < Rails::Application
    config.load_defaults 7.0

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'zh-CN', '*.yml').to_s]
    config.i18n.available_locales = [:en, :'zh-CN']
    config.i18n.default_locale = :en
    config.i18n.fallbacks = [:en]
    config.eager_load_paths += %W(#{Rails.root.join}/lib)

    config.time_zone = 'Beijing'
    config.active_record.default_timezone = :local
    config.active_job.queue_adapter = :sidekiq

    # Keep Rails 4.2 behavior: belongs_to associations are optional by default
    config.active_record.belongs_to_required_by_default = false

    # paper_trail 会把 update/destroy 事件发生前的完整属性快照
    # （包括 created_at/updated_at 等 datetime 列）以 YAML 序列化后
    # 存入 versions.object。Rails 7 起，ActiveRecord 默认只允许
    # Psych 安全反序列化 Symbol（yaml_column_permitted_classes 默认
    # 为 [Symbol]），而这些快照里的 datetime 属性序列化后是 Ruby 的
    # Time 实例，反序列化时会被拒绝，报
    # `Psych::DisallowedClass: Tried to load unspecified class: Time`，
    # 导致任何被编辑过的记录，其 PaperTrail::Version#reify 都会抛出
    # 异常（表现为 products/instances/technologies/matters 四条业务线
    # 详情页的“历史版本”只要有一条 update 版本就 500）。
    #
    # paper_trail (15.x) 的 YAML 序列化器
    # (PaperTrail::Serializers::YAML) 并没有自己独立的白名单，而是
    # 直接读取这个 ActiveRecord 全局配置，所以这里补上 Time 即可，
    # 不需要额外为 paper_trail 单独配置序列化器。
    #
    # 只放行本项目实际用到的 Time，不放行任意类，避免重新打开 YAML
    # 反序列化攻击面（这正是 Rails 7 收紧默认值想要防止的问题）。
    config.active_record.yaml_column_permitted_classes = [Symbol, Time]
  end
end
