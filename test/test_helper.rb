ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/mock'

Dir[Rails.root.join('test', 'support', '**', '*.rb')].sort.each { |f| require f }

class ActiveSupport::TestCase
  include Builders
end

class ActionDispatch::IntegrationTest
  include Builders

  def sign_in_as(user)
    post user_session_path, params: { user: { login: user.login, password: 'password123' } }
    follow_redirect! if response.redirect?
    user
  end
end
