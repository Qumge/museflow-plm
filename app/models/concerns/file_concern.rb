module FileConcern
  extend ActiveSupport::Concern
  included do
    has_one_attached :document

    # attach 一个文件到 document 的同时，把 blob key 镜像写入 file_path、
    # 文件名镜像写入 file_name。ActiveStorage 的挂载关系不进 paper_trail 的
    # 属性快照，*_versions.html.erb 对 version.reify 出来的对象调
    # preview_url/download_url，全靠这两列的镜像才能继续工作
    # （见 download_url 的注释）。
    def attach_document(io:, filename:)
      document.attach(io: io, filename: filename)
      mirror_document_columns(filename)
    end

    # Direct Upload 场景：浏览器已经把字节传到 /rails/active_storage/direct_uploads，
    # 这里拿到的是一个已经存在、尚未挂载的 blob 的 signed_id，只需要把它挂到
    # document 上，不重新上传数据。
    #
    # 用普通的 `document = signed_id` 赋值（而不是 `document.attach(signed_id)`）
    # 是刻意的：ActiveStorage::Attached::One#attach 在 record 已持久化且当前无
    # 未保存改动时，会在 attach 内部立即调用一次*校验过*的 record.save——但这里
    # 的 owner 常常是一条尚未走完审批流程、develop_id/flow_id/active_id 仍为
    # nil 的 Log（do_upload_file 用 `save validate: false` 特意绕过这个校验，
    # 见 file_attachable.rb），那次隐式 save 会因校验失败而静默不落库，
    # 附件表面上"挂上了"（内存里的 attachment_changes 已置位）却没有真正写入
    # ActiveStorage::Attachment 表。改用赋值只是登记一个待保存的变更，真正落库
    # 延后到调用方显式的 save（可以带 validate: false）里一次性完成，跟
    # attach_document 对未持久化记录的处理方式保持一致。
    def attach_document_from_signed_id(signed_id, filename: nil)
      self.document = signed_id
      mirror_document_columns(filename.presence || document.blob&.filename.to_s)
    end

    def preview_url
      download_url
    end

    # 解析顺序刻意是"先按 file_path 查 key，查不到再退回 document 关联"，
    # 不是反过来——原因是 paper_trail 的 version.reify 出来的对象带的是
    # 历史 file_path 快照，但它的 document 关联仍然是按 id 查库，会解析到
    # *当前*（可能早已被后续审批覆盖过）的 attachment，不是这个版本当时的
    # 文件。实测验证过：反过来做（document 优先）会让历史版本的预览显示成
    # 最新文件而不是当时的文件，静默出错且没有任何报错信号。
    #
    # 1. file_path 存在 → 按 key 查 blob。当前记录的 file_path 与
    #    document 的 blob key 由 attach_document / after_active 保持镜像
    #    同步，所以这条路径对当前记录和历史版本都给出正确结果。
    # 2. 查不到（file_path 为空，或是迁移前遗留的、不对应真实 blob 的
    #    字符串，例如旧的 do_upload_file 直接写入的路径）→ 退回当前
    #    document 关联，尽量给出一个可用的链接。
    # 3. 都没有 → nil，不做任何字符串拼接，不会重演 P0 修过的
    #    `qiniu_domain + '/' + file_path` 在 domain 为 nil 时崩溃的问题。
    def download_url
      blob = file_path.present? ? ActiveStorage::Blob.find_by(key: file_path) : nil
      blob ||= document.blob if document.attached?
      return nil unless blob

      Rails.application.routes.url_helpers.rails_blob_url(blob)
    rescue StandardError => e
      Rails.logger.warn "#{self.class}##{id} download_url failed: #{e.class}: #{e.message}"
      nil
    end

    private

    def mirror_document_columns(filename)
      return unless document.attached?

      if persisted?
        update_columns(file_path: document.blob.key, file_name: filename)
      else
        self.file_path = document.blob.key
        self.file_name = filename
      end
    end
  end
end
