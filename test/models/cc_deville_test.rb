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
    url = 'https://pender.checkmedia.org/api/medias.html?url=https://twitter.com/caiosba/status/811777768174260225'

    status = @cc.get_status(url)
    cf = status['data']['caches'].last
    assert_equal 'cloudflare', cf['name']
    old_expiration_time = Time.parse(cf['expires'])

    @cc.clear_cache(url)
    sleep 1

    status = @cc.get_status(url)
    cf = status['data']['caches'].last
    assert_equal 'cloudflare', cf['name']
    new_expiration_time = Time.parse(cf['expires'])

    assert new_expiration_time > old_expiration_time
  end
end
