class AddLocaleToUsers < ActiveRecord::Migration[7.0]
  # P4 Task 3：铺 i18n 骨架。用户可选的语言偏好，可空——不设置时
  # ApplicationController#set_locale 继续按 Accept-Language / 默认语言解析，
  # 不影响存量用户。
  def change
    add_column :users, :locale, :string
  end
end
