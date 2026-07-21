# 未配置 SMTP 时跳过邮件设置，使应用在零第三方账号的情况下仍可启动。
if ENV['SMTP_ADDRESS'].present?
  ActionMailer::Base.smtp_settings = {
    :authentication       => :login,
    :address              => ENV['SMTP_ADDRESS'],
    :port                 => ENV.fetch('SMTP_PORT', '465').to_i,
    :domain               => ENV.fetch('SMTP_DOMAIN', ''),
    :user_name            => ENV['SMTP_USERNAME'],
    :password             => ENV['SMTP_PASSWORD'],
    :tls                  => true,
    :ssl                  => true,
    :enable_starttls_auto => true
  }
end
