require_relative '../test_helper'

class UploadedVideoTest < ActiveSupport::TestCase
  test "should create video" do
    assert_difference 'UploadedVideo.count' do
      m = create_uploaded_video
      pp m
    end
  end
end
