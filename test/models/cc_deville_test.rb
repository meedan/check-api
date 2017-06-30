require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'cc_deville.rb')
require 'cc_deville'

class CcDevilleTest < ActiveSupport::TestCase
  def setup
    super
    @cc = CcDeville.new(CONFIG['cc_deville_host'], CONFIG['cc_deville_token'], CONFIG['cc_deville_httpauth'])
  end

  test "should instantiate" do
    assert_kind_of CcDeville, @cc
  end

  test "should clear cache from Cloudflare" do
    WebMock.stub_request(:delete, /http:\/\/cc-deville.org/).to_return(body: 'ok')
    stub_configs({ 'cc_deville_host' => 'http://cc-deville.org', 'cc_deville_token' => 'test', 'cc_deville_httpauth' => 'u:p' }) do
      CcDeville.clear_cache_for_url('http://test.com')
    end
  end
end
