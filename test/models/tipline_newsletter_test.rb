require_relative '../test_helper'

class TiplineNewsletterTest < ActiveSupport::TestCase
  def setup
    @team = create_team
    @newsletter = TiplineNewsletter.new(
      header_type: 'image',
      header_overlay_text: 'Test',
      introduction: 'Test introduction',
      rss_feed_url: 'https://example.com/feed',
      number_of_articles: 3,
      send_every: 'everyday',
      timezone: 'UTC',
      time: Time.parse('10:00'),
      footer: 'Test',
      language: 'en',
      team: @team
    )
  end

  def teardown
  end

  test 'should persist tipline newsletter' do
    assert_difference 'TiplineNewsletter.count' do
      create_tipline_newsletter
    end
  end

  test 'should be a valid newsletter' do
    assert @newsletter.valid?
  end

  test 'should have introduction' do
    @newsletter.introduction = ''
    assert_not @newsletter.valid?
  end

  test 'should have language' do
    @newsletter.language = nil
    assert_not @newsletter.valid?
  end

  test 'should have a valid RSS feed URL' do
    @newsletter.rss_feed_url = 'not_a_url'
    assert_not @newsletter.valid?
  end

  test 'should have between 0 and 3 articles' do
    @newsletter.number_of_articles = 4
    assert_not @newsletter.valid?
    @newsletter.number_of_articles = 0
    assert @newsletter.valid?
  end

  test 'should have a valid day' do
    @newsletter.send_every = 'invalid_day'
    assert_not @newsletter.valid?
  end

  test 'should have a valid language' do
    @newsletter.language = 'fr'
    assert_not @newsletter.valid?
    @newsletter.language = 'en'
    assert @newsletter.valid?
  end

  test 'should build newsletter with static content from articles' do
    @newsletter.introduction = 'Foo'
    @newsletter.first_article = 'Bar'
    @newsletter.rss_feed_url = nil
    assert_equal "Foo\n\nBar", @newsletter.build_content
  end

  test 'should build newsletter with dynamic content from RSS feed' do
    @newsletter.introduction = 'Foo'
    @newsletter.rss_feed_url = create_rss_feed.url
    assert_equal "Foo\n\nFoo\nhttp://foo\n\nBar\nhttp://bar", @newsletter.build_content
  end

  test 'should track if content has changed' do
    @newsletter.first_article = 'Foo'
    @newsletter.rss_feed_url = nil
    @newsletter.build_content
    assert !@newsletter.content_has_changed?
    @newsletter.first_article = 'Bar'
    assert @newsletter.content_has_changed?
  end

  test 'should not have more than one newsletter for the same team and language' do
    assert_difference 'TiplineNewsletter.count' do
      @newsletter.save!
    end
    assert_raises ActiveRecord::RecordNotUnique do
      newsletter = @newsletter.dup
      newsletter.save!
    end
  end

  test 'should create newsletter for current team' do
    t = create_team
    Team.current = t
    @newsletter.team = nil
    assert @newsletter.valid?
    assert_equal t, @newsletter.team
    Team.current = nil
  end

  test 'should have deliveries' do
    delivery = TiplineNewsletterDelivery.create!(
      recipients_count: 100,
      content: 'Test',
      started_sending_at: Time.now.ago(1.minute),
      finished_sending_at: Time.now,
      tipline_newsletter: @newsletter
    )
    assert_equal [delivery], @newsletter.tipline_newsletter_deliveries
  end

  test 'should have a valid header type' do
    @newsletter.header_type = 'video'
    assert @newsletter.valid?
    @newsletter.header_type = 'foo'
    assert !@newsletter.valid?
  end

  test 'should have a header file' do
    newsletter = create_tipline_newsletter header_file: 'rails.png'
    assert_match /^http/, newsletter.header_file_url
  end

  test 'should format newsletter time as cron' do
    # Offset
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'America/Chicago (GMT-05:00)',
      send_every: 'friday'
    )
    assert_equal '0 15 * * 5', newsletter.cron_notation

    # Offset, other direction
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'Indian/Maldives (GMT+05:00)',
      send_every: 'friday'
    )
    assert_equal '0 5 * * 5', newsletter.cron_notation

    # Non-integer hours offset, but still same day as UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('19:00'),
      timezone: 'Asia/Kolkata (GMT+05:30)',
      send_every: 'sunday'
    )
    assert_equal '30 13 * * 0', newsletter.cron_notation

    # Non-integer hours offset and not same day as UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('1:00'),
      timezone: 'Asia/Kolkata (GMT+05:30)',
      send_every: 'sunday'
    )
    assert_equal '30 19 * * 6', newsletter.cron_notation

    # Integer hours offset and not same day as UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('23:00'),
      timezone: 'America/Los Angeles (GMT-07:00)',
      send_every: 'sunday'
    )
    assert_equal '0 6 * * 1', newsletter.cron_notation

    # Everyday
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'America/New York (GMT-04:00)',
      send_every: 'everyday'
    )
    assert_equal '0 14 * * *', newsletter.cron_notation

    # Legacy 3 letter codes
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'EST',
      send_every: 'sunday'
    )
    assert_equal '0 15 * * 0', newsletter.cron_notation
  end
end
