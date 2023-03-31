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
end
