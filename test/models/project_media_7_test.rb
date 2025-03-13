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

  test "should not create duplicate media from original claim URL as UploadedImage" do
    Tempfile.create(['test_image', '.jpg']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
      file.rewind
      image_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, image_url).to_return(body: file.read, headers: { 'Content-Type' => 'image/jpeg' })

      t = create_team
      create_project team: t

      assert_raise RuntimeError do
        2.times { create_project_media(team: t, set_original_claim: image_url) }
      end
    end
  end

  test "should not create duplicate media from original claim URL as Claim" do
    t = create_team
    create_project team: t

    assert_raise RuntimeError do
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
    [pm1, pm2].each { |pm| publish_report(pm) }
    sleep 1
    fact_checks.delete(pm1.fact_check_id)
    # Should get both explainer and FactCheck
    Rails.cache.delete("relevant-items-#{pm1.id}")
    expected_result = fact_checks.concat([ex2.id, ex3.id]).sort
    assert_equal expected_result, pm1.get_similar_articles.map(&:id).sort
    assert_queries '=', 0 do
      assert_equal expected_result, pm1.get_similar_articles.map(&:id).sort
    end
    # Test with media item
    json_schema = {
      type: 'object',
      required: ['job_name'],
      properties: {
        text: { type: 'string' },
        job_name: { type: 'string' },
        last_response: { type: 'object' }
      }
    }
    create_annotation_type_and_fields('Transcription', {}, json_schema)
    audio = create_uploaded_audio
    pm_a = create_project_media team: t, media: audio
    data = { 'job_status' => 'COMPLETED', 'transcription' => 'Foo Bar'}
    create_dynamic_annotation annotation_type: 'transcription', annotated: pm_a, set_fields: { text: 'Foo Bar', job_name: '0c481e87f2774b1bd41a0a70d9b70d11', last_response: data }.to_json
    sleep 1
    assert_equal [pm1.fact_check_id, pm2.fact_check_id, pm3.fact_check_id].concat([ex1.id, ex2.id, ex3.id]).sort, pm_a.get_similar_articles.map(&:id).sort
    # Verify search query for images
    create_extracted_text_annotation_type
    pm_i = nil
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      Sidekiq::Testing.fake! do
        WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
        WebMock.stub_request(:post, 'http://alegre/image/ocr/').with({ body: { url: "some/path" } }).to_return(body: { text: 'Foo Bar' }.to_json)
        WebMock.stub_request(:post, 'http://alegre/text/similarity/')
        Bot::Alegre.unstub(:media_file_url)
        pm_i = create_project_media team: t, media: create_uploaded_image
        Bot::Alegre.stubs(:media_file_url).with(pm_i).returns('some/path')
        Bot::Alegre.get_extracted_text(pm_i)
        Bot::Alegre.unstub(:media_file_url)
      end
    end
    sleep 1
    assert_equal [pm1.fact_check_id, pm2.fact_check_id, pm3.fact_check_id].concat([ex1.id, ex2.id, ex3.id]).sort, pm_i.get_similar_articles.map(&:id).sort
    Bot::Smooch.unstub(:search_for_explainers)
  end

  test "should not return null when handling fact-check for existing media" do
    t = create_team
    pm1 = create_project_media team: t
    c = create_claim_description project_media: pm1
    create_fact_check claim_description: c, language: 'en'
    pm2 = ProjectMedia.new team: t, set_fact_check: { 'language' => 'en' }
    assert_raise ActiveRecord::RecordInvalid do
      ProjectMedia.handle_fact_check_for_existing_claim(pm1, pm2)
    end
  end

  test "should save the original_claim url and original_claim_hash when Link Media is created from original_claim" do
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
    media = pm_link.media
    
    assert_not_nil media.original_claim
    assert_not_nil media.original_claim_hash
    assert_equal link_url, media.original_claim
  end

  test "should save the original_claim text and original_claim_hash when Claim media is created from original_claim" do
    claim = 'This is a claim.'
    pm_claim = create_project_media(set_original_claim: claim)
    media = pm_claim.media
    
    assert_not_nil media.original_claim
    assert_not_nil media.original_claim_hash
    assert_equal claim, media.original_claim
  end

  test "should save the original_claim url and original_claim_hash when UploadedAudio Media is created from original_claim" do
    Tempfile.create(['test_audio', '.mp3']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      file.rewind
      audio_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, audio_url).to_return(body: file.read, headers: { 'Content-Type' => 'audio/mp3' })
      
      pm_audio = create_project_media(set_original_claim: audio_url)
      media = pm_audio.media
      
      assert_not_nil media.original_claim
      assert_not_nil media.original_claim_hash
      assert_equal audio_url, media.original_claim
    end
  end

  test "should check if the original_claim text exists and return that instance when trying to create claim media" do
    text = 'This is a claim.'

    claim = Claim.create!(quote: text, original_claim: text)
    pm = create_project_media(set_original_claim: text)

    assert_equal claim.id, pm.media.id
  end

  test "should check if the original_claim url exists and return that instance when trying to create UploadedAudio media" do
    Tempfile.create(['test_audio', '.mp3']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      file.rewind
      audio_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, audio_url).to_return(body: file.read, headers: { 'Content-Type' => 'audio/mp3' })

      audio = UploadedAudio.create!(file: file, original_claim: audio_url)
      pm = create_project_media(set_original_claim: audio_url)

      assert_equal audio.id, pm.media.id
    end
  end

  test "should create a Claim media instead of UploadedAudio media if a Timeout is raised when creating from original claim" do
    Tempfile.create(['test_audio', '.mp3']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      file.rewind
      audio_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, audio_url).to_return(body: file.read, headers: { 'Content-Type' => 'audio/mp3' })

      Media.stubs(:downloaded_file).raises(Net::OpenTimeout)

      pm = create_project_media(set_original_claim: audio_url)

      assert_equal 'Claim', pm.media.type
      assert_equal audio_url, pm.media.quote
      assert_not_empty pm.media.original_claim
    end
  end
end
