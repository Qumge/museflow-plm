require 'test_helper'

class ResourceManifestTest < ActiveSupport::TestCase
  # 只检查本应用自己的业务路由。devise 走 devise_controller? 豁免；
  # RailsAdmin / Sidekiq::Web / Turbo Native 都是独立挂载的引擎或框架控制器，
  # 均不继承本应用的 ApplicationController，永远不会跑到 authorize_action!，
  # 因此和业务授权无关。'turbo/' 覆盖 turbo-rails gem 自动挂载的
  # Turbo::Native::NavigationController（继承自 ActionController::Base，
  # 不是本应用 ApplicationController 的子类）——这几条路由不在 routes.rb
  # 源文件里，是 gem 通过 railtie 自动注入的，第一次跑这个测试时才发现。
  #
  # 'landing' 是 P5 Task 10 新增的公开落地页：LandingController 继承
  # ApplicationController，但显式 skip_before_action :authorize_action!
  # （访客未登录，走不到任何业务权限判断），和 devise_controller? 豁免同一个
  # 原理——声明了也恢复不了任何功能，硬要求它进 resources.yml 只是噪音。
  #
  # 'users/registrations' 是 P5 Task 11 的自定义注册控制器
  # （Users::RegistrationsController < Devise::RegistrationsController）。
  # 上面按字符串前缀匹配的 'devise/' 豁免匹配不到它——它的 controller_path
  # 是 "users/registrations"，不是 "devise/registrations"——但它仍然是
  # devise_controller?（继承链上有 DeviseController），authorize_action!
  # 同样从未在它身上跑过，和其余 devise/* 豁免同一个原理，单独列出来。
  EXEMPT_CONTROLLERS = %w[rails_admin sidekiq turbo/ landing users/registrations].freeze

  def app_routes
    Rails.application.routes.routes.filter_map do |route|
      controller = route.defaults[:controller]
      action = route.defaults[:action]
      next if controller.blank? || action.blank?
      next if controller.start_with?(*EXEMPT_CONTROLLERS)
      next if controller.start_with?('devise/')
      next if controller.start_with?('active_storage/', 'action_mailbox/', 'rails/')

      [controller, action]
    end.uniq
  end

  # 一个 (controller, action) 是否真的能被 Rails 派发到，而不是一条声明了
  # 却从未实现的死路由。
  #
  # 早期版本把已知的死路由（如 audits#new、notices#destroy）硬编码进一份
  # "豁免清单"里直接跳过——这是错误的做法：豁免清单会退化成一份需要人工
  # 持续维护的黑名单，下次 routes.rb 里的 `resources` 声明和控制器实现之间
  # 再出现新的不对称（比如新增一个 `resources` 却只实现一半 action），又得
  # 靠人记得回来手工加一条豁免，遗漏的风险和这次要修的漏洞是同一种性质。
  #
  # 判据不再是手搓的启发式（早期版本自己 glob
  # app/views/<controller>/<action>.*，只覆盖了 _prefixes 两级前缀
  # [controller_path, "application"] 里的第一级——如果日后有人在
  # app/views/application/ 下放一个供隐式渲染共用的模板，那种手搓 glob 会
  # 漏判，让"权限清单缺口"重新变得不可见），而是直接调用 Rails 派发 action
  # 时真正用的方法：AbstractController::Base#available_action?（内部即
  # _find_action_name / method_for_action；ImplicitRender 会用
  # `template_exists?(action_name.to_s, _prefixes)` 判断隐式渲染，_prefixes
  # 天然包含 "application" 这一级，见下方"available_action? 判据依据"）。
  # 一个 action 只有在"控制器里定义了同名方法"或"存在同名视图模板会触发隐式
  # 渲染"这两个条件里至少有一个满足时，才可能被真正调用到；否则请求会在
  # before_action 链（包括 authorize_action!）跑之前就被
  # AbstractController::ActionNotFound 拦下——不管访问者是谁，包括
  # super_admin。这类 action 没有必要出现在 config/resources.yml 里，因为
  # 声明了也恢复不了任何功能。
  #
  # 用这个判据，三类情况都是自动处理的，不需要任何手工黑名单：
  # - 死路由（audits#new/create/edit/show/update/destroy、
  #   notices#read/destroy）：无方法、无模板 → dispatchable? 为 false，
  #   自动被排除，不需要声明。
  # - notices#index：没有显式的 controller 方法，但
  #   app/views/notices/index.html.erb 存在 → 触发隐式渲染，dispatchable?
  #   为 true，必须声明。
  # - 真实业务缺口（home#stl、products/instances/technologies#do_apply、
  #   products#import/do_import 等）：controller 方法都存在 →
  #   dispatchable? 为 true，必须声明。
  #
  # available_action? 判据依据：直接实例化候选 controller（不 dispatch、
  # 不建立 request/response），调用其 #available_action?(action_name)。
  # lookup_context（模板查找用）只依赖 self.class._view_paths 和 _prefixes
  # 这两个类级别状态，details_for_lookup 默认返回 {}，因此单纯 `klass.new`
  # 没有可观察的副作用，也不需要伪造一个请求上下文。
  #
  # 必须传 String 而非 Symbol：action_methods 内部是一个由 String 组成的
  # Set，Symbol 传进去 `include?` 恒为 false，会被误判成"控制器方法不存在"
  # 而只剩隐式渲染分支能救；routes.rb 里 route.defaults[:action] 本来就是
  # String，天然满足（已用 rails runner 验证：
  # `available_action?(:do_apply)` 和 `available_action?("do_apply")`
  # 结果不同，前者会误吞进 elsif 分支）。
  def dispatchable?(controller, action)
    klass = "#{controller.camelize}Controller".safe_constantize
    return true unless klass # 保守：无法判断时，要求声明而不是悄悄放行

    !!klass.new.available_action?(action.to_s)
  end

  test "every routable action is declared in config/resources.yml" do
    undeclared = app_routes.select { |controller, action| dispatchable?(controller, action) }
                           .reject { |controller, action| Resource.permitted?(action, controller) }

    assert_empty undeclared,
                 "以下路由未在 config/resources.yml 中声明，授权生效后将对所有非 super_admin 用户不可用：\n" \
                 "#{undeclared.map { |c, a| "  #{c}##{a}" }.join("\n")}"
  end

  test "every declared resource is granted to at least one role" do
    granted = YAML.load_file(Rails.root.join('config', 'role_resources.yml'))
                  .values
                  .flat_map { |targets| targets.flat_map { |t, acts| acts.keys.map { |a| [t, a] } } }
                  .to_set

    ungranted = Resource.manifest.flat_map { |t, acts| acts.keys.map { |a| [t, a] } }
                        .reject { |pair| granted.include?(pair) }

    assert_empty ungranted,
                 "以下权限已声明但没有任何角色被授予，等于死条目：\n" \
                 "#{ungranted.map { |t, a| "  #{t}##{a}" }.join("\n")}"
  end
end
