require 'test_helper'

class MediaTest < ActiveSupport::TestCase
  test "should create media" do
    assert_difference 'Media.count' do
      create_media
    end
  end

  test "should not save media without url" do
    media = Media.new
    assert_not  media.save
  end

  test "set pender data for media" do
    media = create_media
    assert_not_empty media.data
  end
end
