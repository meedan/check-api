require_relative '../test_helper'

class RssFeedTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test 'should get articles' do
    rf = create_rss_feed
    assert_equal 2, rf.get_articles.size
  end

  test 'should raise exception when articles cannot be loaded' do
    require 'rss'
    RSS::Parser.stubs(:parse).raises(StandardError)
    assert_raises RssFeed::RssLoadError do
      rf = create_rss_feed
      rf.get_articles
    end
  end
end
