require_relative '../test_helper'

class UploadedVideoTest < ActiveSupport::TestCase
  test "should create video" do
    assert_difference 'UploadedVideo.count' do
      create_uploaded_video
    end
  end
end
