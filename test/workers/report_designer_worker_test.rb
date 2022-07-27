require_relative '../test_helper'

class ReportDesignerWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
  end

  test "should send message to Smooch users" do
    Bot::Alegre.stubs(:request_api).returns({ success: true })
    Sidekiq::Testing.inline!
    r = publish_report
    Bot::Smooch.stubs(:send_report_to_users).once
    assert_nothing_raised do
      ReportDesignerWorker.perform_async(r.id, 'publish')
    end
    Bot::Smooch.unstub(:send_report_to_users)
    Bot::Alegre.unstub(:request_api)
  end

  test "should have an interval between retries" do
    assert_equal 1, ReportDesignerWorker.retry_in_callback
  end

  test "should save error after many retries" do
    Bot::Alegre.stubs(:request_api).returns({ success: true })
    r = publish_report
    assert r.get_field_value('last_error').blank?
    ReportDesignerWorker.retries_exhausted_callback({ 'args' => [r.id], 'error_message' => 'Test' }, StandardError.new)
    assert_match /Test/, r.reload.get_field_value('last_error')
    Bot::Alegre.unstub(:request_api)
  end
end
