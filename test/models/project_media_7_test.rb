require_relative '../test_helper'
require 'tempfile'

class ProjectMedia7Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
  end

  test "should create media from original claim URL as Link" do
    setup_elasticsearch

    # Mock Pender response for Link
    link_url = 'https://example.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    link_response = {
      type: 'media',
      data: {
        url: link_url,
        type: 'item'
      }
    }.to_json
    WebMock.stub_request(:get, pender_url).with(query: { url: link_url }).to_return(body: link_response)
    pm_link = create_project_media(set_original_claim: link_url)
    assert_equal 'Link', pm_link.media.type
    assert_equal link_url, pm_link.media.url
  end

  test "should create media from original claim URL as UploadedImage" do
    Tempfile.create(['test_image', '.jpg']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
      file.rewind
      image_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, image_url).to_return(body: file.read, headers: { 'Content-Type' => 'image/jpeg' })
      pm_image = create_project_media(set_original_claim: image_url)
      assert_equal 'UploadedImage', pm_image.media.type
    end
  end

  test "should create media from original claim URL as UploadedVideo" do
    Tempfile.create(['test_video', '.mp4']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.mp4')))
      file.rewind
      video_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, video_url).to_return(body: file.read, headers: { 'Content-Type' => 'video/mp4' })
      pm_video = create_project_media(set_original_claim: video_url)
      assert_equal 'UploadedVideo', pm_video.media.type
    end
  end

  test "should create media from original claim URL as UploadedAudio" do
    Tempfile.create(['test_audio', '.mp3']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      file.rewind
      audio_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, audio_url).to_return(body: file.read, headers: { 'Content-Type' => 'audio/mp3' })
      pm_audio = create_project_media(set_original_claim: audio_url)
      assert_equal 'UploadedAudio', pm_audio.media.type
    end
  end

  test "should create media from original claim text as Claim" do
    pm_claim = create_project_media(set_original_claim: 'This is a claim.')
    assert_equal 'Claim', pm_claim.media.type
    assert_equal 'This is a claim.', pm_claim.media.quote
  end
end
