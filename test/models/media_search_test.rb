require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediaSearchTest < ActiveSupport::TestCase
  def setup
    super
    MediaSearch.delete_index
    MediaSearch.create_index
    sleep 1
  end

  test "should create media search" do
    assert_difference 'MediaSearch.length' do
      create_media_search
    end
  end

  test "should set type automatically" do
    m = create_media_search
    assert_equal 'mediasearch', m.annotation_type
  end
end
