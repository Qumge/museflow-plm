require 'test_helper'

class ActiveStorageAuthTest < ActionDispatch::IntegrationTest
  BLOB = { filename: 'x.pdf', byte_size: 5,
           checksum: Digest::MD5.base64digest('hello'),
           content_type: 'application/pdf' }.freeze

  test "direct upload endpoint rejects anonymous requests" do
    post rails_direct_uploads_path, params: { blob: BLOB }.to_json,
         headers: { 'CONTENT_TYPE' => 'application/json' }

    assert_response :redirect, 'ActiveStorage 的控制器不经过 ApplicationController，' \
                              '必须显式加 authenticate_user!，否则匿名可创建 blob'
  end

  test "direct upload endpoint still works for a signed-in user" do
    admin = create_user(login: 'superadmin', role: create_role('super_admin'))
    sign_in_as admin

    post rails_direct_uploads_path, params: { blob: BLOB }.to_json,
         headers: { 'CONTENT_TYPE' => 'application/json' }

    assert_response :success
    assert_includes response.body, 'signed_id'
  end
end
