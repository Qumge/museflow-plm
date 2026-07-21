# ActiveStorage 的控制器直接继承 ActionController::Base，不经过本应用的
# ApplicationController，因此 authenticate_user! 与 authorize_action! 都不会生效。
#
# 未加保护时，任何匿名请求都能 POST /rails/active_storage/direct_uploads
# 创建 blob——部署到对象存储（R2/S3）后，这是一个可以被用来消耗存储配额和
# 账单的开放入口。
#
# blob 的读取端点（/rails/active_storage/blobs/...）使用签名 ID，属于
# capability-based 访问，不在此处拦截。
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    before_action :authenticate_user!
  end
end
