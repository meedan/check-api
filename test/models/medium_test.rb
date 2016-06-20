require 'test_helper'

class MediumTest < ActiveSupport::TestCase

  test "should create media" do
    assert_difference 'Medium.count' do
      create_media
    end
  end

  test "should not save media without url" do
    media = Medium.new
    assert_not  media.save
  end

  test "set pender data for media" do
    media = create_media
    assert_not_empty media.data
  end
end
