class HomeController < ApplicationController
  layout "cytoscape", :only => [ :cytoscape ]
  def files_search
    data = []
    if params[:table_search].present?
      instances = Instance.search_conn(params)
      products = Product.search_conn(params)
      technologies = Technology.search_conn(params)
      data = (instances + products + technologies).sort{ |a, b| b.updated_at <=> a.updated_at }
    end
    @datas = Kaminari.paginate_array(data).page(params[:page]).per(Settings.per_page)
  end

  # 新注册用户默认 role: nil（P5 Task 11 打开注册开关后就会真的出现这种
  # 账号），Ability 仍然放行 can?(:index, :home)（见 app/models/ability.rb
  # 顶部的 `can :index, :home` 对任何登录用户无条件成立），所以不会被
  # authorize_action! 拦在门外——但没有 role 也就没有任何
  # products/instances/technologies 权限，四条线全空，原来的实现会直接
  # 渲染一张"No data to display"的空表格，和系统故障长得一模一样。这里显式
  # 分流，给一条看得懂的提示（P5 Task 12）。用 resources.blank? 而不只是
  # role.blank?，是因为角色本身可以存在但被配成零权限（见
  # test/support/builders.rb 的 create_role resource_specs: :none）——这种
  # 账号同样是"进来了但什么都做不了"，该给同一条提示。
  #
  # !! super_admin 必须单独豁免：它的权限来自 Ability 里硬编码的
  # `can :manage, :all`（对 has_role?('super_admin') 无条件成立），从不
  # 经过逐条 resources 授权——config/role_resources.yml 里压根没有
  # super_admin 这个顶层键，Role.load! 建出来的 super_admin 角色本来就是
  # 零 resources（实测 User.find_by(login: 'admin').resources.blank? =>
  # true）。第一版实现漏了这一条，会把超级管理员自己也判成"无角色"，
  # 登录后看到提示而不是仪表盘——用运行中的 server 实测发现，不是纸面推理。
  # 和 app/models/user.rb 的 has_product_log_resource? 等方法同一个写法：
  # `has_role?('super_admin') || 逐条 resources 判断`。
  def index
    if current_user.role.blank? || (current_user.resources.blank? && !current_user.has_role?('super_admin'))
      @no_role_access = true
      return
    end

    instances = current_user.instances.search_conn(params).where('instances.file_path is not null')
    products = current_user.products.search_conn(params).where('products.file_path is not null')
    technologies = Technology.search_conn(params).where('technologies.file_path is not null')
    data = (instances + products + technologies).sort{ |a, b| b.updated_at <=> a.updated_at }
    @datas = Kaminari.paginate_array(data).page(params[:page]).per(Settings.per_page)
  end

  def cytoscape
    @products = Product.includes(:instances, :technology).references(:all)
    @instances = Instance.includes(:products, :technology).references(:all)
    @technologies = Technology.all
    @technologies1 = Technology.includes({products: :instances}).references(:all)
    @technologies2 = Technology.includes({instances: :products}).references(:all)
    @product_instances = ProductsInstance.includes(product: :technology, instance: :technology).references(:all)
    #@technology_instances = TechnologyInstance.includes(:technology, instance: :products).references(:all)

    if params[:product_id].present?
      @products = @products.where('products.id = ?', params[:product_id])
      @instances = @instances.where('products.id = ?', params[:product_id])
      @technologies1 = @technologies1.where('products.id = ?', params[:product_id])
      @technologies2 = @technologies2.where('products.id = ?', params[:product_id])
      @product_instances = @product_instances.where('products.id = ?', params[:product_id])
      #@technology_instances = @technology_instances.where('products.id = ?', params[:product_id])
      @technologies = (@technologies1 + @technologies2).uniq

    elsif params[:instance_id].present?
      @products = @products.where('instances.id = ?', params[:instance_id])
      @instances = @instances.where('instances.id = ?', params[:instance_id])
      @technologies1 = @technologies1.where('instances.id = ?', params[:instance_id])
      @technologies2 = @technologies2.where('instances.id = ?', params[:instance_id])
      @product_instances = @product_instances.where('instances.id = ?', params[:instance_id])
      @technologies = (@technologies1 + @technologies2).uniq
      #@technology_instances = @technology_instances.where('instances.id = ?', params[:instance_id])
    elsif params[:technology_id].present?
      @products = @products.where('technologies.id = ?', params[:technology_id])
      @instances = @instances.where('technologies.id = ?', params[:technology_id])
      @technologies = Technology.where('technologies.id = ?', params[:technology_id])
      @product_instances = @product_instances.where('technologies.id = ?', params[:technology_id])
      #@technology_instances = @technology_instances.where('technologies.id = ?', params[:technology_id])
    end
  end
end
