require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediaSearchTest < ActiveSupport::TestCase

  test "should create media search" do
    assert_difference 'MediaSearch.length' do
      create_media_search
    end
  end

end
