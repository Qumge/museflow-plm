require 'test_helper'

# 四条业务线的控制器目前 80-84% 重复，P2 会将其合并。
# 本测试用同一组断言跑遍四条线——既提供合并前后的对照基线，
# 也让"某条线在合并中被漏掉"这类错误立刻暴露。
class BusinessLinesTest < ActionDispatch::IntegrationTest
  LINES = {
    'products'     => { path: '/products',     factory: :create_product },
    'instances'    => { path: '/instances',    factory: :create_instance },
    'technologies' => { path: '/technologies', factory: :create_technology },
    'matters'      => { path: '/matters',      factory: :create_matter }
  }.freeze

  def setup
    @admin = create_user(login: 'superadmin', role: create_role('super_admin'))
    sign_in_as @admin
  end

  LINES.each do |name, config|
    test "#{name} index renders" do
      send(config[:factory], user: @admin)

      get config[:path]

      assert_response :success
    end

    test "#{name} index shows an existing record" do
      record = send(config[:factory], user: @admin)

      get config[:path]

      assert_includes response.body, ERB::Util.html_escape(record.name)
    end

    test "#{name} detail page renders" do
      record = send(config[:factory], user: @admin)

      get "#{config[:path]}/#{record.id}"

      assert_response :success
      assert_includes response.body, ERB::Util.html_escape(record.name)
    end

    test "#{name} search filters by name" do
      match = send(config[:factory], user: @admin, name: 'Findable Widget')
      other = send(config[:factory], user: @admin, name: 'Unrelated Thing')

      get config[:path], params: { table_search: 'Findable' }

      assert_response :success
      assert_includes response.body, 'Findable Widget'
      assert_not_includes response.body, ERB::Util.html_escape(other.name)
    end
  end

  test "technologies show_version renders instead of raising MissingTemplate" do
    tech = create_technology(user: @admin)
    tech.update!(name: 'Versioned Process')
    version = tech.versions.last

    get show_version_technology_path(tech, version_id: version&.id)

    assert_response :success
  end

  # ------------------------------------------------------------------
  # Bug: 任何被编辑过的记录，其详情页返回 500。
  #
  # 根因：paper_trail 在 `update` 事件下会把变更前的完整属性快照
  # （含 created_at/updated_at 等 datetime 列）以 YAML 存入
  # versions.object。Rails 7 / Psych 4 默认只允许反序列化 Symbol
  # （ActiveRecord.yaml_column_permitted_classes 默认值为 [Symbol]），
  # 所以 `version.reify` 一遇到 Time/TimeWithZone 就抛出
  # Psych::DisallowedClass。四条业务线的 `_versions.html.erb`
  # （渲染在详情页的“历史版本”里）都会对每一条 version 调用
  # `reify`，因此详情页只要有一条 update 版本就会 500。
  #
  # 现有测试没抓到，是因为它们只创建记录、从不编辑——`create` 事件
  # 不产生 object 快照，`reify` 对它直接返回 nil，不会走到有问题的
  # 反序列化路径。上面的 show_version 测试虽然调用了 update!，但
  # `versions.last`（配合 model 上 `order("id desc")` 的 scope）取到
  # 的其实是最早的 create 版本而不是 update 版本，同样绕开了 bug。
  #
  # 本测试直接请求详情页：_versions.html.erb 会遍历全部 version 并
  # 逐个 reify，所以不受上述 .last/.first 顺序陷阱影响。
  # ------------------------------------------------------------------
  LINES.each do |name, config|
    test "#{name} detail page still renders after the record has been edited" do
      # technologies/_versions.html.erb 对每条 version 都无条件调用
      # show_file_name(version.reify)，不像其余三条线那样先判断
      # file_path.present?。这是一个与本 bug 无关的既有小 bug——
      # file_name 为 nil 时 show_file_name 会 NoMethodError。为了让
      # 本测试只针对 reify/Psych 这一个 bug，这里给 technologies 预先
      # 造好 file_name/file_path（现实中 technology 经过审批流程后
      # 也确实会有文件，见 TechnologyLog#do_active_audit!）。
      record = if name == 'technologies'
                 send(config[:factory], user: @admin, file_name: 'drawing.pdf', file_path: 'uploads/drawing.pdf')
               else
                 send(config[:factory], user: @admin)
               end

      # matters 的 has_paper_trail 只追踪 file_path/file_name
      # （见 app/models/matter.rb），改 name 不会产生新版本，
      # 所以需要单独改 file_path/file_name 才能制造出 update 版本。
      if name == 'matters'
        record.update!(file_path: 'uploads/edited.pdf', file_name: 'edited.pdf')
      else
        record.update!(name: 'Edited Name')
      end

      assert record.versions.where(event: 'update').exists?,
             '本测试的前提是必须真的产生一条 update 版本'

      get "#{config[:path]}/#{record.id}"

      assert_response :success
    end
  end

  test "notices index renders instead of raising for a missing partial" do
    get notices_path
    assert_response :success
  end
end
