# 从 params[:locale] > current_user 偏好 > 浏览器 Accept-Language > 默认语言
# 依次选出本次请求要用的 I18n.locale。
#
# 抽成 concern（而不是只留在 ApplicationController 里）是因为 RailsAdmin
# 挂载的是它自己的控制器树（RailsAdmin::ApplicationController，默认继承
# ActionController::Base，不是本应用的 ApplicationController——见
# config/initializers/rails_admin.rb 里对它的说明），如果只有
# ApplicationController 一份 before_action，rails_admin 的请求完全不会
# 触发 set_locale。I18n.locale 是进程内的线程局部状态：不设置不代表落回
# 默认语言，而是直接沿用"这个线程上一次处理的、随便哪个请求"留下的值——
# 在多线程 Puma 下，管理后台可能会随机显示上一个用户切换后留下的语言，
# 和当前用户的选择或默认语言都对不上（P4 Task 7 上线后用真实 HTTP 请求
# 走查 rails_admin 时实测复现：同一批 `?locale=en` 请求里，User/Role 页面
# 的角色下拉选项和部分标签仍是中文，因为服务这几个请求的线程上一次刚好
# 处理过别的 zh-CN 请求）。
module LocaleSelectable
  extend ActiveSupport::Concern

  included do
    # 排在最前面：locale 不该依赖登录状态——未登录的登录页也要能切换语言。
    # prepend: true 保证不管这个 concern 是在目标类定义时就 include，还是
    # 像 RailsAdmin::ApplicationController 那样在 gem 加载完之后才回填
    # 进去，set_locale 都排在该控制器其余 before_action（包括 RailsAdmin
    # 自己的 _authenticate!／本应用的 authenticate_user!）之前——否则未授权
    # 跳转带的 flash 文案会用错语言。
    before_action :set_locale, prepend: true
  end

  private

  # 任何一级给出的值只要不在 available_locales 里就跳过，绝不会把 I18n.locale
  # 设成一个未加载翻译文件的语言。
  def set_locale
    I18n.locale = locale_from_params || locale_from_user || locale_from_header || I18n.default_locale
    persist_locale_choice
  end

  # 用户通过 ?locale= 主动切换时，把选择记到 users.locale，下次干净请求
  # （点导航、直接进某页）就能沿用，而不是每次都回落到默认语言。
  #
  # 用 update_column：跳过验证与回调，也不触发 Warden/会话写入——set_locale
  # 是 prepend 到最前的 before_action，若在 CSRF 校验前搅动会话会让登录 422
  # （P4 踩过一次）。只写这一列、只在值确实变了时写，最省事也最安全。
  def persist_locale_choice
    return unless current_user
    chosen = locale_from_params
    return if chosen.nil? || current_user.locale == chosen.to_s

    current_user.update_column(:locale, chosen.to_s)
  end

  def locale_from_params
    normalize_locale(params[:locale])
  end

  def locale_from_user
    current_user && normalize_locale(current_user.locale)
  end

  def locale_from_header
    header = request.env['HTTP_ACCEPT_LANGUAGE']
    return nil if header.blank?

    header.split(',').each do |part|
      tag = part.split(';').first.to_s.strip
      locale = normalize_locale(tag)
      return locale if locale
    end
    nil
  end

  # 大小写不敏感地匹配到 available_locales 里的 symbol；匹配不到返回 nil，
  # 让调用方落到优先级链的下一级。
  def normalize_locale(value)
    return nil if value.blank?

    I18n.available_locales.find { |locale| locale.to_s.casecmp?(value.to_s) }
  end
end
