require_relative '../test_helper'

class TiplineNewsletterTest < ActiveSupport::TestCase
  def setup
    WebMock.stub_request(:get, /#{CheckConfig.get('narcissus_url')}/).to_return(body: '{"url":"http://screenshot/test/test.png"}')
    @team = create_team
    @newsletter = TiplineNewsletter.new(
      header_type: 'image',
      header_overlay_text: 'Test',
      introduction: 'Test introduction',
      content_type: 'rss',
      rss_feed_url: 'https://example.com/feed',
      number_of_articles: 3,
      send_every: ['monday'],
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
    @newsletter.send_every = 'tuesday'
    assert_not @newsletter.valid?
    @newsletter.send_every = ['invalid_day']
    assert_not @newsletter.valid?
  end

  test 'should have a valid language' do
    @newsletter.language = 'fr'
    assert_not @newsletter.valid?
    @newsletter.language = 'en'
    assert @newsletter.valid?
  end

  test 'should build newsletter with static content from articles' do
    @newsletter.content_type = 'static'
    @newsletter.introduction = 'Foo'
    @newsletter.first_article = 'Bar'
    assert_equal "Foo\n\nBar", @newsletter.build_content
  end

  test 'should build newsletter with dynamic content from RSS feed' do
    @newsletter.introduction = 'Foo'
    @newsletter.rss_feed_url = create_rss_feed.url
    assert_equal "Foo\n\nFoo\nhttp://foo\n\nBar\nhttp://bar", @newsletter.build_content
  end

  test 'should track if content has changed' do
    newsletter = create_tipline_newsletter content_type: 'static', first_article: 'Foo', rss_feed_url: nil
    newsletter.build_content
    assert !newsletter.content_has_changed?
    newsletter = TiplineNewsletter.find(newsletter.id)
    assert !newsletter.content_has_changed?
    newsletter = TiplineNewsletter.find(newsletter.id)
    newsletter.first_article = 'Bar'
    newsletter.save!
    assert newsletter.content_has_changed?
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
    Sidekiq::Testing.inline! do
      TiplineNewsletter.any_instance.stubs(:new_file_uploaded?).returns(true)
      newsletter = create_tipline_newsletter header_type: 'image', header_file: 'rails.png'
      assert_match /^http/, newsletter.header_file_url
      assert_match /^http/, newsletter.reload.header_media_url
    end
  end

  test 'should return number of subscribers' do
    newsletter = create_tipline_newsletter
    assert_equal 0, newsletter.subscribers_count
    create_tipline_subscription(team_id: newsletter.team_id, language: newsletter.language)
    assert_equal 1, newsletter.subscribers_count
  end

  test 'should save information about last user who scheduled or paused a newsletter' do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    create_team_user team: t, user: u2, role: 'editor'
    newsletter = nil
    with_current_user_and_team(u, t) do
      newsletter = create_tipline_newsletter team: t, enabled: false
      assert_nil newsletter.reload.last_scheduled_by
      assert_nil newsletter.reload.last_scheduled_at
      newsletter = TiplineNewsletter.find(newsletter.id) ; newsletter.introduction = random_string ; newsletter.save!
      assert_nil newsletter.reload.last_scheduled_by
      assert_nil newsletter.reload.last_scheduled_at
      newsletter = TiplineNewsletter.find(newsletter.id) ; newsletter.enabled = true ; newsletter.save!
      assert_equal u, newsletter.reload.last_scheduled_by
      assert_not_nil newsletter.reload.last_scheduled_at
    end
    with_current_user_and_team(u2, t) do
      newsletter = TiplineNewsletter.find(newsletter.id) ; newsletter.enabled = false ; newsletter.save!
      assert_equal u, newsletter.reload.last_scheduled_by
      newsletter = TiplineNewsletter.find(newsletter.id) ; newsletter.introduction = random_string ; newsletter.save!
      assert_equal u, newsletter.reload.last_scheduled_by
      newsletter = TiplineNewsletter.find(newsletter.id) ; newsletter.enabled = true ; newsletter.save!
      assert_equal u2, newsletter.reload.last_scheduled_by
    end
  end

  test 'should return WhatsApp template name' do
    @newsletter.content_type = 'static'
    assert_equal 'newsletter_image_no_articles', @newsletter.whatsapp_template_name
  end

  test 'should have a valid content type' do
    @newsletter.content_type = 'static'
    assert @newsletter.valid?
    @newsletter.content_type = 'rss'
    assert @newsletter.valid?
    @newsletter.content_type = 'foo'
    assert !@newsletter.valid?
  end

  test 'should convert video header file' do
    WebMock.stub_request(:get, /:9000/).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp4')))
    TiplineNewsletter.any_instance.stubs(:new_file_uploaded?).returns(true)
    Sidekiq::Testing.inline! do
      newsletter = create_tipline_newsletter header_type: 'video', header_file: 'rails.mp4'
      assert_match /^http/, newsletter.header_file_url
      assert_match /^http/, newsletter.reload.header_media_url
    end
  end

  test 'should format RSS newsletter time as cron' do
    # Offset
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:32'),
      timezone: 'America/Chicago (GMT-05:00)',
      send_every: ['friday']
    )
    assert_equal '32 15 * * 5', newsletter.cron_notation

    # Offset, other direction
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'Indian/Maldives (GMT+05:00)',
      send_every: ['friday']
    )
    assert_equal '0 5 * * 5', newsletter.cron_notation

    # Non-integer hours offset, but still same day as UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('19:00'),
      timezone: 'Asia/Kolkata (GMT+05:30)',
      send_every: ['sunday']
    )
    assert_equal '30 13 * * 0', newsletter.cron_notation

    # Non-integer hours offset and not same day as UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('1:00'),
      timezone: 'Asia/Kolkata (GMT+05:30)',
      send_every: ['sunday']
    )
    assert_equal '30 19 * * 6', newsletter.cron_notation

    # Integer hours offset and not same day as UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('23:00'),
      timezone: 'America/Los Angeles (GMT-07:00)',
      send_every: ['sunday']
    )
    assert_equal '0 6 * * 1', newsletter.cron_notation

    # Everyday
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'America/New York (GMT-04:00)',
      send_every: ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
    )
    assert_equal '0 14 * * *', newsletter.cron_notation

    # Legacy 3 letter codes
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'EST',
      send_every: ['sunday']
    )
    assert_equal '0 15 * * 0', newsletter.cron_notation

    # Multiple days of the week
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'America/New York (GMT-04:00)',
      send_every: ['monday', 'wednesday', 'friday']
    )
    assert_equal '0 14 * * 1,3,5', newsletter.cron_notation
  end

  test 'should format static newsletter time UTC date time object' do
    # Offset
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:32'),
      timezone: 'America/Chicago (GMT-05:00)',
      send_on: Date.parse('2023-10-30')
    )
    assert_equal '2023-10-30 15:32', newsletter.scheduled_time.strftime("%Y-%m-%d %H:%M")

    # Offset, other direction
    newsletter = TiplineNewsletter.new(
      time: Time.parse('10:00'),
      timezone: 'Indian/Maldives (GMT+05:00)',
      send_on: Date.parse('2023-10-30')
    )
    assert_equal '2023-10-30 05:00', newsletter.scheduled_time.strftime("%Y-%m-%d %H:%M")

    # Non-integer hours offset, but still same day as UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('19:00'),
      timezone: 'Asia/Kolkata (GMT+05:30)',
      send_on: Date.parse('2023-10-30')
    )
    assert_equal '2023-10-30 13:30', newsletter.scheduled_time.strftime("%Y-%m-%d %H:%M")

    # Non-integer hours offset and one day before in UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('1:00'),
      timezone: 'Asia/Kolkata (GMT+05:30)',
      send_on: Date.parse('2023-10-30')
    )
    assert_equal '2023-10-29 19:30', newsletter.scheduled_time.strftime("%Y-%m-%d %H:%M")

    # Integer hours offset and one day after in UTC
    newsletter = TiplineNewsletter.new(
      time: Time.parse('23:00'),
      timezone: 'America/Los Angeles (GMT-07:00)',
      send_on: Date.parse('2023-12-31')
    )
    assert_equal '2024-01-01 06:00', newsletter.scheduled_time.strftime("%Y-%m-%d %H:%M")
  end
end
