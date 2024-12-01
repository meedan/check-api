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

  test "should not create duplicate media from original claim URL as Link" do
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

    t = create_team
    create_project team: t

    assert_raise RuntimeError do
      2.times { create_project_media(team: t, set_original_claim: link_url) }
    end
  end

  test "should create duplicate media from original claim URL as UploadedImage" do
    Tempfile.create(['test_image', '.jpg']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
      file.rewind
      image_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, image_url).to_return(body: file.read, headers: { 'Content-Type' => 'image/jpeg' })

      t = create_team
      create_project team: t

      assert_difference 'ProjectMedia.count', 2 do
        2.times { create_project_media(team: t, set_original_claim: image_url) }
      end
    end
  end

  test "should create duplicate media from original claim URL as Claim" do
    t = create_team
    create_project team: t

    assert_difference 'ProjectMedia.count', 2 do
      2.times { create_project_media(team: t, set_original_claim: 'This is a claim.') }
    end
  end

  test "should search for item similar articles" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch
    t = create_team
    pm1 = create_project_media quote: 'Foo Bar', team: t
    pm2 = create_project_media quote: 'Foo Bar Test', team: t
    pm3 = create_project_media quote: 'Foo Bar Test Testing', team: t
    ex1 = create_explainer language: 'en', team: t, title: 'Foo Bar'
    ex2 = create_explainer language: 'en', team: t, title: 'Foo Bar Test'
    ex3 = create_explainer language: 'en', team: t, title: 'Foo Bar Test Testing'
    pm1.explainers << ex1
    pm2.explainers << ex2
    pm3.explainers << ex3
    ex_ids = [ex1.id, ex2.id, ex3.id]
    Bot::Smooch.stubs(:search_for_explainers).returns(Explainer.where(id: ex_ids))
    # Should get explainer
    assert_equal [ex2.id, ex3.id], pm1.get_similar_articles.map(&:id).sort
    fact_checks = []
    [pm1, pm2, pm3].each do |pm|
      cd = create_claim_description description: pm.title, project_media: pm
      fc = create_fact_check claim_description: cd, title: pm.title
      fact_checks << fc.id
    end
    [pm1, pm2, pm3].each { |pm| publish_report(pm) }
    sleep 2
    fact_checks.delete(pm1.fact_check_id)
    # Should get both explainer and FactCheck
    assert_equal fact_checks.concat([ex2.id, ex3.id]).sort, pm1.get_similar_articles.map(&:id).sort
    Bot::Smooch.unstub(:search_for_explainers)
  end
end
