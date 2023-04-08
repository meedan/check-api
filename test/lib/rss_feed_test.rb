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
end
