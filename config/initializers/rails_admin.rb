RailsAdmin.config do |config|
  config.asset_source = :sprockets

  config.current_user_method(&:current_user)

  config.authenticate_with do
    redirect_to main_app.root_path, alert: I18n.t('flash.unauthorized') unless current_user.present? && current_user.has_role?('super_admin')
  end

  config.main_app_name = ["Muse", "Flow"]
  config.included_models = ['User', 'Resource', 'Role', 'Category', 'InstanceCategory', 'Organization']

  # P4 Task 7：这里原来用 label / label_plural DSL 硬编码了 24 个中文串，
  # 绕过 I18n、无法随 locale 切换（也是"模型名"的第四套定义机制，和
  # config/locales/*/model.yml 各说各话——同一个 user.login 这里叫"账号"，
  # model.yml 叫"帐号"）。RailsAdmin 3 的字段/模型 label 默认走
  # ActiveRecord::Base#human_attribute_name / model_name.human，原生读取
  # activerecord.attributes.* / activerecord.models.*（见
  # rails_admin/config/fields/{base,association}.rb、
  # rails_admin/config/model.rb），gem 自带完整的 en 译文。删掉 DSL 后这些
  # label 全部改从 config/locales/{en,zh-CN}/model.yml 取，跟随 locale 切换，
  # 且和应用其余部分共用同一份译名。
  #
  # 每个 `field :x` 调用本身必须保留（实测踩过的坑：`field(name, ...,
  # add_to_section = true)` 一旦被调用就把该 field 标成 `defined = true`；
  # RailsAdmin::Config::HasFields#fields 只有在"这个 model 一个 field 都没被
  # 显式声明过"时才回退到展示全部字段——见
  # rails_admin/lib/rails_admin/config/has_fields.rb。整段删掉
  # `field :login do ... end` 这类块，而不是只删里面的 label，会把
  # login/email/password/phone/name 这几个字段直接从后台表单里隐藏掉，是
  # 功能回归，不只是翻译问题）。所以这里逐个保留原来声明过的字段清单，只删
  # 掉块里的 `label '...'` 那一行；`associated_collection_cache_all` 等和
  # i18n 无关的配置原样保留。
  config.model 'Category' do
    field :name
  end

  config.model 'InstanceCategory' do
    field :name
    field :desc
  end

  config.model 'User' do
    field :login
    field :email
    field :password
    field :phone
    field :name
    field :organization do
      associated_collection_cache_all true
    end
    field :role do
      associated_collection_cache_all true
    end
  end

  config.model 'Role' do
    # 后台在列表/关联列里显示角色时用 display_name（走 i18n），而不是数据库
    # 原始的 name 列（固定中文）。否则英文界面下用户表的 Role 列仍是中文。
    # 只影响 RailsAdmin 的展示；主应用另走 Role#display_name，不受影响。
    object_label_method :display_name

    field :name
    field :desc
    field :resources do
      associated_collection_cache_all true
    end
  end

  config.model 'Resource' do
    field :name
    field :action
    field :target
  end

  config.model 'Organization' do
    field :name
    field :desc
  end

  config.actions do
    dashboard
    index
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
  end
end

# RailsAdmin::ApplicationController < ActionController::Base（RailsAdmin::Config
# 的 parent_controller 默认值），不继承本应用的 ApplicationController，所以
# ApplicationController#set_locale 从来没有机会在 rails_admin 请求上跑一遍——
# 见 app/controllers/concerns/locale_selectable.rb 顶部注释，这是 Task 7 把
# 这里的 label 从硬编码 DSL 换成 I18n 之后才暴露出来的真问题：不设置不等于
# 落回默认语言，是直接沿用同一个 Puma 线程上一次随便哪个请求留下的
# I18n.locale，多线程下管理后台的语言可能和当前用户的选择对不上。
#
# 不改 config.parent_controller 去继承本应用 ApplicationController——那会把
# authenticate_user!/authorize_action!/my_notices 等和 rails_admin 无关的业务
# before_action 也带进来，影响面远大于"只是设置语言"。这里只把
# LocaleSelectable 这一个 concern 补回 RailsAdmin 自己的控制器基类。
#
# 包在 to_prepare 里：RailsAdmin::ApplicationController 是 gem（引擎）自己
# autoload 的常量，在这个初始化文件执行的时点还没被引用过、不存在，直接
# 引用会在启动时报 NameError；to_prepare 保证在所有 autoload 路径就绪之后
# 才跑。开发环境下 to_prepare 每次触发重新加载都会再跑一遍，加 include?
# 前置判断避免重复 include 把 before_action 累加成多份。
Rails.application.config.to_prepare do
  RailsAdmin::ApplicationController.include(LocaleSelectable) unless RailsAdmin::ApplicationController.include?(LocaleSelectable)
end
