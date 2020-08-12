require_relative '../test_helper'

class UploadedAudioTest < ActiveSupport::TestCase
  test "should create audio" do
    assert_difference 'UploadedAudio.count' do
      m = create_uploaded_audio
    end
  end

  test "should upload allowed extensions only" do
    assert_no_difference 'UploadedAudio.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_audio file: 'rails.flv'
      end
    end
  end

  test "should create uploaded audio through project media" do
    pm = ProjectMedia.new
    pm.team_id = create_team.id
    pm.file = File.new(File.join(Rails.root, 'test', 'data', 'rails.mp3'))
    pm.media_type = 'UploadedAudio'
    pm.disable_es_callbacks = true
    pm.save!
    # verify file path
    assert_not_nil pm.reload.media.file_path
  end
end
