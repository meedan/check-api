require_relative '../test_helper'

class TiplineNewsletterTest < ActiveSupport::TestCase
  def setup
    @team = create_team
    @newsletter = TiplineNewsletter.new(
      introduction: 'Test introduction',
      rss_feed_url: 'https://example.com/feed',
      number_of_articles: 3,
      send_every: 'everyday',
      timezone: 'UTC',
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

  test 'should have team' do
    @newsletter.team = nil
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
