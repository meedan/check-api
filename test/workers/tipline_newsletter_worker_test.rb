require_relative '../test_helper'

class TiplineNewsletterWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    setup_smooch_bot(true)
    create_tipline_subscription team_id: @team.id
    rss = '<rss version="1"><channel><title>x</title><link>x</link><description>x</description><item><title>x</title><link>x</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
  end

  test "should send newsletter" do
    assert_nothing_raised do
      TiplineNewsletterWorker.perform_async(@team.id, 'en')
    end
  end

  test "should not crash if error happens when sending newsletter to some subscriber" do
    Bot::Smooch.stubs(:send_final_message_to_user).raises(StandardError)
    assert_nothing_raised do
      TiplineNewsletterWorker.perform_async(@team.id, 'en')
    end
    Bot::Smooch.unstub(:send_final_message_to_user)
  end

  test "should skip sending newsletter if content hasn't changed" do
    assert_equal 1, TiplineNewsletterWorker.new.perform(@team.id, 'en')
    assert_equal 0, TiplineNewsletterWorker.new.perform(@team.id, 'en')
  end
end
