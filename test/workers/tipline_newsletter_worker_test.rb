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

  test "should not crash if exception happens when sending newsletter to some subscriber" do
    Bot::Smooch.stubs(:send_message_to_user).raises(StandardError)
    assert_nothing_raised do
      TiplineNewsletterWorker.perform_async(@team.id, 'en')
    end
    Bot::Smooch.unstub(:send_message_to_user)
  end

  test "should not crash if error happens when sending newsletter to some subscriber" do
    Bot::Smooch.stubs(:send_message_to_user).returns(OpenStruct.new(code: 400))
    assert_nothing_raised do
      TiplineNewsletterWorker.perform_async(@team.id, 'en')
    end
    Bot::Smooch.unstub(:send_message_to_user)
  end

  test "should skip sending newsletter if content hasn't changed" do
    assert_equal 1, TiplineNewsletterWorker.new.perform(@team.id, 'en')
    assert_equal 0, TiplineNewsletterWorker.new.perform(@team.id, 'en')
  end

  test "should not send newsletter if it's not enabled" do
    tn = TiplineNewsletter.where(team: @team, language: 'en').last
    tn.enabled = false
    tn.save!
    assert_equal 0, TiplineNewsletterWorker.new.perform(@team.id, 'en')
  end

  test "should not send two newsletters if rescheduled" do
    Sidekiq::Testing.fake! do
      tn = TiplineNewsletter.where(team: @team, language: 'en').last
      tn.content_type = 'static'
      tn.enabled = true
      tn.updated_at = Time.now
      tn.save!
      assert_equal 0, TiplineNewsletterWorker.new.perform(@team.id, 'en')
    end
  end

  test "should save a delivery event when newsletter is sent" do
    assert_difference 'TiplineNewsletterDelivery.count' do
      TiplineNewsletterWorker.new.perform(@team.id, 'en')
    end
  end

  test "should calculate number of newsletters sent" do
    travel_to DateTime.new(2023, 01, 05)
    rss = '<rss version="1"><channel><title>x</title><link>x</link><item><title>y</title><link>y</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
    TiplineNewsletterWorker.new.perform(@team.id, 'en')
    assert_equal 1, CheckStatistics.number_of_newsletters_sent(@team.id, Time.parse('2023-01-01'), Time.parse('2023-01-31'), 'en')

    travel_to DateTime.new(2023, 02, 10)
    rss = '<rss version="1"><channel><title>x</title><link>x</link><item><title>z</title><link>z</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
    TiplineNewsletterWorker.new.perform(@team.id, 'en')
    assert_equal 1, CheckStatistics.number_of_newsletters_sent(@team.id, Time.parse('2023-02-01'), Time.parse('2023-02-28'), 'en')

    assert_equal 2, CheckStatistics.number_of_newsletters_sent(@team.id, Time.parse('2023-01-01'), Time.parse('2023-03-01'), 'en')
  end

  test "should skip sending newsletter if RSS content can't be loaded" do
    TiplineNewsletter.any_instance.stubs(:content_has_changed?).raises(RssFeed::RssLoadError)
    assert_equal 0, TiplineNewsletterWorker.new.perform(@team.id, 'en')
  end
end
