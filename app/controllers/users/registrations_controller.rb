# P5 Task 11.
#
# 现状（已实测）：`:registerable` 一直开着，/users/sign_up 无条件可达，
# 而这是一个单租户自部署的企业 PLM——所有登录用户看到的是同一家公司的
# 图纸，任何人自助注册即可进来查看在真实部署里是安全问题。改为默认关闭，
# 由 ENV['ALLOW_REGISTRATION'] 显式打开（.env.example 已加注释说明风险）。
#
# 且原本即使注册"成功"也永远登不进去——但实测下来，真正的根因和最初的
# 判断不完全一样，记在这里免得下次又猜错：
#
# Devise::ParameterSanitizer#initialize 会用 `resource_class
# .authentication_keys` 作为每个 action 默认放行列表的起点（见
# devise/parameter_sanitizer.rb 的 extract_auth_keys + permit 实现），本
# 系统 authentication_keys = [:login]，所以 sign_up 的默认放行列表其实是
# [:login, :password, :password_confirmation]——login 本来就在，从未被丢。
# 真正被丢的是 :email：Devise 内置的 DEFAULT_PERMITTED_ATTRIBUTES[:sign_up]
# 只有 [:password, :password_confirmation]，普通 Devise 项目里"看起来"
# email 也被默认放行，只是因为那些项目的 authentication_keys 恰好是
# [:email]、被当成起点带进去了；本系统把 authentication_key 换成了
# login，这个隐式依赖就露出来了。email 建表时 NOT NULL 且
# :validatable 要求非空格式合法，一旦被强参数吞掉，User.create 直接校验
# 失败、整条记录都不会落库——"注册成功但登不进去"的说法其实还不够准确，
# 实测是"注册这一步本身就没成功"。
# （用 bin/rails runner 实例化 Devise::ParameterSanitizer.new(User, :user,
# ...).sanitize(:sign_up) 直接对比放行前后的 keys 复现，而非凭猜测。）
#
# 两个键都显式放行，不依赖上面这条隐式的 auth_keys 兜底行为——万一日后
# authentication_keys 改了，这里不该跟着悄悄改变行为。
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :ensure_registration_enabled, only: %i[new create]
  before_action :configure_sign_up_params, only: [:create]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[login email])
  end

  private

  def ensure_registration_enabled
    return if ENV['ALLOW_REGISTRATION'] == 'true'

    redirect_to new_user_session_path, alert: t('devise_views.registration_disabled')
  end
end
