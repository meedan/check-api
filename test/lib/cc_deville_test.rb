require_relative '../test_helper'
require 'minitest/autorun'

class CcDevilleTest < ActiveSupport::TestCase
  test "should clear cache" do
    WebMock.stub_request(:post, /api\.cloudflare\.com/).to_return(body: {
      "success": true,
      "errors": [],
      "messages": [],
      "result": {
        "id": "9a7806061c88ada191ed06f989cc3dac"
      }
    }.to_json)
    stub_configs({ 'cloudflare_auth_email' => 'foo', 'cloudflare_auth_key' => 'bar', 'cloudflare_zone' => 'baz' }) do
      assert_nothing_raised do
        CcDeville.clear_cache_for_url('http://test.com')
      end
    end
  end

  test "should handle errors from Cloudflare" do
    WebMock.stub_request(:post, /api\.cloudflare\.com/).to_return(body: {
      "result": nil,
      "success": false,
      "errors": [{"code":1003,"message":"Invalid or missing zone id."}],
      "messages": []
    }.to_json)
    stub_configs({ 'cloudflare_auth_email' => 'foo', 'cloudflare_auth_key' => 'bar', 'cloudflare_zone' => 'baz' }) do
      mocked_method = Minitest::Mock.new
      mocked_method.expect :call, :return_value, [CcDeville::CloudflareResponseError], url: 'http://test.com'

      CheckSentry.stub :notify, mocked_method do
        CcDeville.clear_cache_for_url('http://test.com')
      end
      mocked_method.verify
    end
  end

  test "should handle connection errors to Cloudflare" do
    WebMock.stub_request(:post, /api\.cloudflare\.com/).to_raise(StandardError.new('test message'))
    stub_configs({ 'cloudflare_auth_email' => 'foo', 'cloudflare_auth_key' => 'bar', 'cloudflare_zone' => 'baz' }) do
      mocked_method = Minitest::Mock.new
      # We expect URL to be passed as second arg here like test above, but Minitest is
      # having problems detecting it passed via matcher
      mocked_method.expect :call, :return_value, [StandardError], url: 'http://test.com'
      CheckSentry.stub :notify, mocked_method do
        CcDeville.clear_cache_for_url('http://test.com')
      end
      mocked_method.verify
    end
  end
end
