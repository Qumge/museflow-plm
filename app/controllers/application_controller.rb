class ApplicationController < ActionController::Base
  include LocaleSelectable

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #
  # prepend: true 是必须的。LocaleSelectable 用 `before_action :set_locale,
  # prepend: true` 把自己排到最前，而 set_locale 会读 current_user（取用户的
  # 语言偏好）——那会在 CSRF 校验之前触发 Warden 认证并搅动会话，导致登录
  # POST 一律 422（实测复现：全新 cookie jar + 正确 token 仍然失败）。
  # 让 CSRF 校验自己也 prepend，且因为这行在 include 之后执行，它会被排到
  # set_locale 更前面，从而恢复"先验 token，再做其他任何事"的正确顺序。
  protect_from_forgery with: :exception, prepend: true

  before_action :authenticate_user!
  before_action :authorize_action!, unless: :devise_controller?
  before_action :set_paper_trail_whodunnit
  before_action :my_notices

  # 全站写操作几乎都是 `$.ajax({ dataType: 'script', ... })`（参见
  # app/views/products/_apply_form.html.erb、
  # app/views/audits/products/_apply_products.html.erb 等），Rails 据 Accept
  # 头把这类请求隐式识别为 format.js（这些控制器动作本就没有 respond_to，
  # 全靠隐式格式渲染 *.js.erb 模板，说明 request.format 在这里已经正确落在
  # :js 上）。这类请求如果仍然无差别 redirect_to，浏览器的 XHR 会自动跟随
  # 302 到 root_path 拿回 home#index 的整页 HTML，被 jQuery 当 JS eval：
  # 有 error 回调的地方弹英文 "Connection error"，审批那条路径连 error
  # 回调都没有，会直接静默卡死、spinner 永不消失。因此按格式分流：浏览器
  # 整页导航（format.html）继续走 redirect_to，走 layouts/_tips 正常展示中文
  # flash；AJAX/JS 请求（format.js）改为直接返回一段可执行的 JS，复用全站
  # 统一的 show_flash(type, message) 提示约定（定义于
  # app/assets/javascripts/application.js，'failed' 对应失败态样式）并主动
  # hideSpinner()，避免界面卡死。
  rescue_from CanCan::AccessDenied do
    respond_to do |format|
      format.html { redirect_to root_path, alert: t('flash.unauthorized') }
      # to_json safely quotes/escapes the translated string for embedding in the
      # rendered JS literal (handles the em-dash-free "You are not authorized..."
      # in en as easily as any future translation with quotes or unicode in it).
      format.js   { render js: "hideSpinner(); show_flash('failed', #{t('flash.unauthorized').to_json});" }
      format.any  { redirect_to root_path, alert: t('flash.unauthorized') }
    end
  end

  def my_notices
    if current_user.present?
      @unread_notices = current_user.unread_notices
      @unreply_notices = current_user.unreply_notices
    end
  end

  private

  # Ability 按 (action, controller) symbol 组织，与 config/resources.yml 的
  # target/action 结构一一对应，因此这一处即覆盖全部业务控制器。
  def authorize_action!
    authorize! action_name.to_sym, controller_name.to_sym
  end
end
