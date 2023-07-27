require_relative '../test_helper'
require_relative '../../lib/lapis_webhook'

class LapisWebhookTest < ActiveSupport::TestCase
  def setup
    url = URI.join(random_url, '/webhook/')
    WebMock.stub_request(:post, url).to_return(status: 200)
    @lw = Lapis::Webhook.new(url, { foo: 'bar' }.to_json)
    super
  end

  test "should instantiate" do
    assert_not_nil @lw
  end

  test "should have signature" do
    assert_kind_of String, @lw.notification_signature({ foo: 'bar' }.to_json)
  end

  test "should notify" do
    assert_kind_of Net::HTTPOK, @lw.notify
  end
end
