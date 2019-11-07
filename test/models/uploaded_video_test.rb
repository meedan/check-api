require_relative '../test_helper'

class UploadedVideoTest < ActiveSupport::TestCase
  test "should create video" do
    assert_difference 'UploadedVideo.count' do
      m = create_uploaded_video
    end
  end

  test "should upload allowed extensions only" do
    assert_no_difference 'UploadedImage.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_video file: 'rails.flv'
      end
    end
  end

  test "should create uploaded video through project media" do
    pm = ProjectMedia.new
    pm.project_id = create_project.id
    pm.file = File.new(File.join(Rails.root, 'test', 'data', 'rails.mp4'))
    pm.media_type = 'UploadedVideo'
    pm.disable_es_callbacks = true
    pm.save!
  end

  test "should create thumbnail" do
    v = create_uploaded_video
    assert_not_nil v.file_path
    assert_not_nil v.thumbnail_path
    assert_not_nil v.embed_path
    assert_not_nil v.file.thumb
    assert_not_nil v.file.embed
    assert_not_nil v.picture
  end
end
