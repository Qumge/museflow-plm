# 唯一无需登录即可访问的页面（P5 Task 10）。只有在访客未登录时才会被路由
# 命中——config/routes.rb 里的 `authenticated :user` 块排在它前面，已登录
# 用户在路由层就直接分流到 home#index，这里不需要再判断一次、也不会多一
# 次跳转。
#
# 继承 ApplicationController 是为了复用 set_locale（未登录也要能切语言）
# 和统一的 500/404 处理，但必须 skip 掉两个会拦住匿名访问的 before_action：
#   - authenticate_user!：不 skip 的话，访客会被弹回登录页，落地页失去意义
#   - authorize_action!：拿 controller_name（"landing"）去 config/resources.yml
#     查表，而 landing 不在那 7 个业务 target 里，find 不到会直接 403
class LandingController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :authorize_action!

  layout 'landing'

  def show
  end
end
