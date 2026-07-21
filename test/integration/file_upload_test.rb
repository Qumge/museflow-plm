require 'test_helper'

# P3 把文件存储从七牛云迁到 ActiveStorage，前端（Task 7）改用 Direct Upload：
# 浏览器先把字节传到 /rails/active_storage/direct_uploads 拿到一个已存在、
# 尚未挂载的 blob，再把它的 signed_id（不再是七牛返回的 key 字符串）连同
# file_name 一起 PATCH/POST 给这六个写入 action。本文件原本用
# `params[:path]` 字符串语义钉死这六个 action 的行为，这里改写为
# `params[:signed_id]` 语义，并把断言从"随便一个字符串"升级为"确实挂载了
# 一个真实 blob"，继续覆盖同样的行为，作为迁移的安全网。
#
# products/instances/technologies 三条线共享 FileAttachable concern 里的
# do_upload_file（新建 Log）/ update_file（更新既有 Log），断言落在
# Log 记录本身；matters#do_upload_file 语义不同——直接更新 Matter 自身，
# 并维护 UserMatter 关联；notices 的 create/update 在提交 signed_id 时
# 写一条 Attachment（列名是 path，不是 file_path——这个不对称正是下面已知
# bug 的根源）。
class FileUploadTest < ActionDispatch::IntegrationTest
  # owner_key 是 Log 模型对父记录的关联名（同时也是 create_log 用来定位
  # LOG_PARENT_KEYS 的 key），三条线除了这个名字，其余行为一致。
  LOG_LINES = {
    'products'     => { path: 'products',     factory: :create_product,    log_class: ProductLog,    owner_key: :product },
    'instances'    => { path: 'instances',    factory: :create_instance,   log_class: InstanceLog,   owner_key: :instance },
    'technologies' => { path: 'technologies', factory: :create_technology, log_class: TechnologyLog, owner_key: :technology }
  }.freeze

  def setup
    @admin = create_user(login: 'uploadadmin', role: create_role('super_admin'))
    sign_in_as @admin
  end

  # ------------------------------------------------------------------
  # do_upload_file × 3：新建 Log，挂载 blob，写 file_path / file_name / user
  # ------------------------------------------------------------------
  LOG_LINES.each do |name, config|
    test "#{name} do_upload_file creates a Log with a real attached blob" do
      record = send(config[:factory], user: @admin)
      blob = create_blob(filename: 'drawing.pdf')

      patch "/#{config[:path]}/#{record.id}/do_upload_file",
            params: { signed_id: blob.signed_id, file_name: 'drawing.pdf' }

      assert_response :success
      log = config[:log_class].where(config[:owner_key] => record).last
      assert log.present?, "expected a #{config[:log_class]} to be created for #{record.class}##{record.id}"
      # file_path 现在必须是真实 blob 的 key（不再是前端随便传的字符串），
      # 且 document 关联本身也要真的挂上——这是 Direct Upload 迁移要修的洞：
      # 迁移前 file_path 只是镜像了七牛返回的 key，从不对应任何 ActiveStorage
      # 记录，预览/下载全靠巧合才能工作。
      assert_equal blob.key, log.file_path
      assert_equal 'drawing.pdf', log.file_name
      assert_equal @admin, log.user
      assert log.document.attached?, 'signed_id 对应的 blob 应该被真正挂载到 document 上'
      assert_equal blob.id, log.document.blob_id
    end

    test "#{name} do_upload_file bypasses Log validations, so develop_id/flow_id/active_id stay nil" do
      # Log 有 validates_presence_of :develop_id, :flow_id, :active_id，
      # 但 do_upload_file 用 `@log.save validate: false` 绕过——这里如实
      # 固化这个现状（现状如此，不是我们认为它"应该"如此）。
      record = send(config[:factory], user: @admin)
      blob = create_blob(filename: 'drawing.pdf')

      patch "/#{config[:path]}/#{record.id}/do_upload_file",
            params: { signed_id: blob.signed_id, file_name: 'drawing.pdf' }

      log = config[:log_class].where(config[:owner_key] => record).last
      assert log.persisted?
      assert_not log.valid?, 'develop_id/flow_id/active_id 缺失，模型本身应判定为无效（只是 save 时被 validate: false 绕过了）'
      assert_nil log.develop_id
      assert_nil log.flow_id
      assert_nil log.active_id
    end

    # ------------------------------------------------------------------
    # update_file × 3：更新既有 Log 的 file_path / file_name / document
    # ------------------------------------------------------------------
    test "#{name} update_file updates file_path/file_name and swaps the attached blob on an existing Log" do
      record = send(config[:factory], user: @admin)
      log = create_log(config[:log_class], parent: record, user: @admin, status: 'wait')
      blob = create_blob(filename: 'updated.pdf')

      # update_file 没有显式 render，走隐式模板查找（update_file.js.erb，
      # 没有 .html.erb 版本），所以必须显式声明 format: :js，否则会拿到
      # ActionController::UnknownFormat。
      patch "/#{config[:path]}/#{log.id}/update_file",
            params: { format: :js, signed_id: blob.signed_id, file_name: 'updated.pdf' }

      assert_response :success
      log.reload
      assert_equal blob.key, log.file_path
      assert_equal 'updated.pdf', log.file_name
      assert log.document.attached?, 'update_file 应该把新 blob 真正挂载到 document 上'
      assert_equal blob.id, log.document.blob_id
    end

    test "#{name} update_file only allows the current user to touch their own Log" do
      # set_log 用 current_user.<x>_logs.find_by 定位记录——即使
      # current_user 是 super_admin，也只能改自己创建的 Log。别人创建的
      # Log 在这里找不到，直接被重定向到 index，数据库不变。
      record = send(config[:factory], user: @admin)
      other = create_user(login: "#{name}_other_owner", role: create_role('super_admin'))
      log = create_log(config[:log_class], parent: record, user: other, status: 'wait')
      blob = create_blob(filename: 'hacked.pdf')

      patch "/#{config[:path]}/#{log.id}/update_file",
            params: { format: :js, signed_id: blob.signed_id, file_name: 'hacked.pdf' }

      assert_redirected_to "/#{config[:path]}"
      log.reload
      assert_equal 'uploads/drawing.pdf', log.file_path, '未经授权的更新不应生效，file_path 应保持 create_log 时写入的原值'
      assert_equal 'drawing.pdf', log.file_name
      assert_not log.document.attached?, '未经授权的更新不应挂载新 blob'
    end
  end

  # ------------------------------------------------------------------
  # matters#do_upload_file：语义不同——直接更新 Matter 自身，并维护
  # UserMatter 关联（不像另外三条线那样新建一条 Log）
  # ------------------------------------------------------------------
  test "matters do_upload_file updates the Matter itself and creates a UserMatter" do
    matter = create_matter(user: @admin)
    blob = create_blob(filename: 'bom.pdf')

    assert_difference -> { UserMatter.count }, 1 do
      patch "/matters/#{matter.id}/do_upload_file",
            params: { signed_id: blob.signed_id, file_name: 'bom.pdf' }
    end

    assert_response :success
    matter.reload
    assert_equal blob.key, matter.file_path
    assert_equal 'bom.pdf', matter.file_name
    assert_equal @admin, matter.file_user
    assert_not_nil matter.last_update_at
    assert matter.document.attached?, 'signed_id 对应的 blob 应该被真正挂载到 Matter#document 上'
    assert_equal blob.id, matter.document.blob_id

    user_matter = UserMatter.find_by(user: @admin, matter: matter)
    assert user_matter.present?
  end

  test "matters do_upload_file does not duplicate the UserMatter on repeat uploads" do
    matter = create_matter(user: @admin)
    first_blob = create_blob(filename: 'first.pdf')
    patch "/matters/#{matter.id}/do_upload_file",
          params: { signed_id: first_blob.signed_id, file_name: 'first.pdf' }

    second_blob = create_blob(filename: 'second.pdf')
    assert_no_difference -> { UserMatter.count } do
      patch "/matters/#{matter.id}/do_upload_file",
            params: { signed_id: second_blob.signed_id, file_name: 'second.pdf' }
    end

    matter.reload
    assert_equal second_blob.key, matter.file_path
    assert_equal 'second.pdf', matter.file_name
    assert matter.document.attached?
    assert_equal second_blob.id, matter.document.blob_id
  end

  # ------------------------------------------------------------------
  # notices#create / #update：带附件时写一条 Attachment（列名是 path，
  # 不是 file_path——这个不对称正是下面已知 bug 的根源）
  # ------------------------------------------------------------------
  test "notices create without a signed_id does not create an Attachment" do
    target = create_product(user: @admin)

    assert_no_difference -> { Attachment.count } do
      post '/notices', params: {
        format: :js,
        notice: { title: 'No attachment', content: 'Body', model_val: "Product_#{target.id}", need_reply: 0 }
      }
    end

    assert_response :success
    notice = Notice.last
    assert notice.present?
    assert_nil notice.file
  end

  test "notices create with a signed_id creates an Attachment with a real attached blob (path column, not file_path)" do
    target = create_product(user: @admin)
    blob = create_blob(filename: 'notice.pdf')

    assert_difference -> { Attachment.count }, 1 do
      post '/notices', params: {
        format: :js,
        signed_id: blob.signed_id, file_name: 'notice.pdf',
        notice: { title: 'Heads up', content: 'Please review', model_val: "Product_#{target.id}", need_reply: 0 }
      }
    end

    assert_response :success
    notice = Notice.last
    attachment = notice.file
    assert attachment.present?
    assert_equal blob.key, attachment.path
    assert_equal 'notice.pdf', attachment.file_name
    assert attachment.document.attached?, 'signed_id 对应的 blob 应该被真正挂载到 Attachment#document 上'
    assert_equal blob.id, attachment.document.blob_id
  end

  test "notices update with a signed_id creates a new Attachment for the Notice" do
    target = create_product(user: @admin)
    notice = @admin.send_notices.create!(title: 'Original', content: 'Body',
                                          model_type: 'Product', model_id: target.id)
    blob = create_blob(filename: 'notice-v2.pdf')

    assert_difference -> { Attachment.count }, 1 do
      patch "/notices/#{notice.id}", params: {
        format: :js,
        signed_id: blob.signed_id, file_name: 'notice-v2.pdf',
        notice: { title: 'Original', content: 'Body', model_val: "Product_#{target.id}", need_reply: 0 }
      }
    end

    assert_response :success
    notice.reload
    attachment = notice.file
    assert attachment.present?
    assert_equal blob.key, attachment.path
    assert_equal 'notice-v2.pdf', attachment.file_name
    assert attachment.document.attached?
    assert_equal blob.id, attachment.document.blob_id
  end

  # Task 4 修复前，这条路径会抛 ActionView::Template::Error：
  # _form.html.erb 调用 `@notice&.file&.file_path`，而 Attachment 只有
  # path 列。修复后改视图为 `&.path`，这里翻转成对失败路径的正常断言。
  #
  # Task 7 把 _form.html.erb 里内嵌的 `var file_path = '<%= ...&.path %>'`
  # 去掉了（Direct Upload 不再需要把存储 key 预置到一个 JS 变量里兜底重新
  # 提交），所以"重渲染的表单带出既有附件"这件事不能再通过在 response.body
  # 里搜索原始 path 字符串来验证，改为直接断言 DB 状态（附件没被动过）+
  # 页面仍然显示该附件的文件名。
  #
  # 另有一个与此无关的既有 bug：notices#edit 连 edit.html.erb / edit.js.erb
  # 模板都不存在，GET /notices/:id/edit 会直接抛
  # ActionController::MissingExactTemplate。当前 UI 无可达入口，仅记录。
  test "notices update re-renders the form when validation fails on a Notice that has an attachment" do
    target = create_product(user: @admin)
    notice = @admin.send_notices.create!(title: 'Original', content: 'Body',
                                          model_type: 'Product', model_id: target.id)
    Attachment.create!(file_name: 'a.pdf', path: 'uploads/a.pdf', model_type: 'Notice', model_id: notice.id)

    patch "/notices/#{notice.id}", params: {
      format: :js,
      notice: { title: '', content: '' } # 触发 validates_presence_of，@flag = false
    }

    assert_response :success
    assert_equal 'Original', notice.reload.title, '校验失败不应修改记录'
    assert_equal 'uploads/a.pdf', notice.file.path, '校验失败不应动到已存在的附件'
    assert_match 'a.pdf', response.body, '重渲染的表单应带出既有附件的文件名'
  end
end
