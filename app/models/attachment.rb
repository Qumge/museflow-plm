class Attachment < ApplicationRecord
  # notices 专用的遗留附件模型（列是 path，不是 file_path）。跟 FileConcern
  # 覆盖的 6 个模型不共享 concern（列名不同），但用同样的 ActiveStorage 化
  # 思路、同样的 nil 安全策略：有 attachment 用它，没有则按 path 当 blob
  # key 查一次，都没有就返回 nil，不做字符串拼接。
  has_one_attached :document

  # Direct Upload 版本的 attach：Attachment 在这里总是新建（notices#create /
  # #update 每次都 `Attachment.new`，从不复用旧记录，同一条 Notice 换附件即新增
  # 一行），所以不必像 FileConcern 那样处理"已持久化记录"分支——赋值即可，
  # 落库延后到调用方对 Notice 的那次 save（把这条新建的 Attachment 一并
  # autosave 下去）。
  def attach_document_from_signed_id(signed_id)
    self.document = signed_id
    self.path = document.blob.key if document.attached?
  end

  def preview_url
    blob = path.present? ? ActiveStorage::Blob.find_by(key: path) : nil
    blob ||= document.blob if document.attached?
    return nil unless blob

    Rails.application.routes.url_helpers.rails_blob_url(blob)
  rescue StandardError => e
    Rails.logger.warn "Attachment##{id} preview_url failed: #{e.class}: #{e.message}"
    nil
  end
end
