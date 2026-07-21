module Builders
  # 第一个被创建的 User 会被 User#assign_super_admin_if_first_user 提权为
  # super_admin。所有需要普通角色用户的测试都必须先调用本方法吸收该副作用。
  def absorb_first_user_promotion!
    return if User.exists?

    User.create!(email: 'first@example.com', login: 'first',
                 password: 'password123', password_confirmation: 'password123')
  end

  def create_role(desc, resource_specs: :all)
    Resource.load!
    role = Role.find_or_create_by!(desc: desc) { |r| r.name = desc }
    role.resources =
      case resource_specs
      when :all  then Resource.all.to_a
      when :none then []
      else resource_specs.map { |action, target| Resource.find_by!(action: action, target: target) }
      end
    role.save!
    role
  end

  def create_user(login:, role: nil, organization: nil)
    absorb_first_user_promotion!
    User.create!(email: "#{login}@example.com", login: login, name: login.titleize,
                 password: 'password123', password_confirmation: 'password123',
                 role: role, organization: organization)
  end

  def create_product(user:, **attrs)
    Product.create!({ name: "Product #{SecureRandom.hex(4)}",
                      product_no: "P-#{SecureRandom.hex(4)}",
                      user: user }.merge(attrs))
  end

  def create_instance(user:, **attrs)
    Instance.create!({ name: "Part #{SecureRandom.hex(4)}",
                       instance_no: "I-#{SecureRandom.hex(4)}",
                       user: user }.merge(attrs))
  end

  def create_technology(user:, **attrs)
    Technology.create!({ name: "Process #{SecureRandom.hex(4)}",
                         no: "T-#{SecureRandom.hex(4)}",
                         user: user }.merge(attrs))
  end

  def create_matter(user:, **attrs)
    Matter.create!({ name: "BOM #{SecureRandom.hex(4)}", user: user }.merge(attrs))
  end

  # 三个 Log 模型的父关联名各不相同，其余字段一致。
  LOG_PARENT_KEYS = {
    'ProductLog'    => :product,
    'InstanceLog'   => :instance,
    'TechnologyLog' => :technology
  }.freeze

  # Log 模型有 validates_presence_of :develop_id, :flow_id, :active_id，
  # 三个审批人必填，否则 save 会失败。
  def create_log(log_class, parent:, user:, status: 'wait')
    parent_key = LOG_PARENT_KEYS.fetch(log_class.name)
    log_class.create!(parent_key => parent, user: user, status: status,
                      file_name: 'drawing.pdf', file_path: 'uploads/drawing.pdf',
                      develop_id: user.id, flow_id: user.id, active_id: user.id)
  end

  def create_product_log(product:, user:, status: 'wait')
    create_log(ProductLog, parent: product, user: user, status: status)
  end

  # Direct Upload 场景下，前端在提交业务表单前已经把字节传到
  # /rails/active_storage/direct_uploads，拿到一个真实存在、尚未挂载的 blob。
  # 测试里用这个方法模拟"文件已经传完"这一步，返回的 blob 拿 .signed_id
  # 就是控制器 action 期望收到的 params[:signed_id]。
  def create_blob(filename: 'drawing.pdf', content: 'pdf bytes', content_type: 'application/pdf')
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new(content), filename: filename, content_type: content_type)
  end
end
