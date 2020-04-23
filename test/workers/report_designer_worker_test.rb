require_relative '../test_helper'

class ReportDesignerWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}|#{CONFIG['storage']['endpoint']}/
  end

  test "should send message to Smooch users" do
    Sidekiq::Testing.inline!
    r = publish_report
    Bot::Smooch.stubs(:send_report_to_users).once
    assert_nothing_raised do
      ReportDesignerWorker.perform_async(r.id, 'publish')
    end
    Bot::Smooch.unstub(:send_report_to_users)
  end

  test "should save error after many retries" do
    r = publish_report
    assert r.get_field_value('last_error').blank?
    ReportDesignerWorker.retry_callback({ 'args' => [r.id], 'error_message' => 'Test' })
    assert_match /Test/, r.reload.get_field_value('last_error')
  end
end
