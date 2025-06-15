require_relative '../test_helper'

class ProjectMedia3Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
  end

  test "should cache published value" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      pm = create_project_media
      pm2 = create_project_media team: pm.team
      create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
      assert_queries(0, '=') { assert_equal 'unpublished', pm.report_status }
      assert_queries(0, '=') { assert_equal 'unpublished', pm2.report_status }
      r = publish_report(pm)
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal 'published', pm.report_status }
      assert_queries(0, '=') { assert_equal 'published', pm2.report_status }
      r = Dynamic.find(r.id)
      r.set_fields = { state: 'paused' }.to_json
      r.action = 'pause'
      r.save!
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal 'paused', pm.report_status }
      assert_queries(0, '=') { assert_equal 'paused', pm2.report_status }
      Rails.cache.clear
      assert_queries(0, '>') { assert_equal 'paused', pm.report_status }
      pm3 = create_project_media team: pm.team
      assert_queries(0, '=') { assert_equal 'unpublished', pm3.report_status }
      r = create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
      assert_queries(0, '=') { assert_equal 'paused', pm3.report_status }
      r.destroy!
      assert_queries(0, '=') { assert_equal 'unpublished', pm3.report_status }
    end
  end

  test "should cache tags list" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      pm = create_project_media
      assert_queries(0, '=') { assert_equal '', pm.tags_as_sentence }
      t = create_tag tag: 'foo', annotated: pm
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal 'foo', pm.tags_as_sentence }
      create_tag tag: 'bar', annotated: pm
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal 'foo, bar'.split(', ').sort, pm.tags_as_sentence.split(', ').sort }
      t.destroy!
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal 'bar', pm.tags_as_sentence }
      Rails.cache.clear
      assert_queries(0, '>') { assert_equal 'bar', pm.tags_as_sentence }
    end
  end

  test "should cache media published at" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      url = 'http://twitter.com/test/123456'
      pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
      response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"1989-01-25 08:30:00"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      pm = create_project_media media: nil, url: url
      assert_queries(0, '=') { assert_equal 601720200, pm.media_published_at }
      response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"1989-01-25 08:31:00"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
      pm = ProjectMedia.find(pm.id)
      pm.refresh_media = true
      pm.save!
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal 601720260, pm.media_published_at }
    end
  end

  test "should cache number of related items" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      t = create_team
      pm1 = create_project_media team: t
      pm2 = create_project_media team: t
      assert_queries(0, '=') { assert_equal 0, pm1.related_count }
      assert_queries(0, '=') { assert_equal 0, pm2.related_count }
      r = create_relationship source_id: pm1.id, target_id: pm2.id
      assert_queries(0, '=') { assert_equal 1, pm1.related_count }
      assert_queries(0, '=') { assert_equal 1, pm2.related_count }
      r.destroy!
      assert_queries(0, '=') { assert_equal 0, pm1.related_count }
      assert_queries(0, '=') { assert_equal 0, pm2.related_count }
    end
  end

  test "should cache type of media" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch
    pm = create_project_media disable_es_callbacks: false
    assert_queries(0, '=') { assert_equal 'Claim', pm.type_of_media }
    Rails.cache.clear
    assert_queries(1, '=') { assert_equal 'Claim', pm.type_of_media }
    assert_queries(0, '=') { assert_equal 'Claim', pm.type_of_media }
    sleep 2
    es = $repository.find(get_es_id(pm))
    assert_equal Media.types.index(pm.type_of_media), es['type_of_media']
  end

  test "should get original title for uploaded files" do
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media media: create_uploaded_image
    create_claim_description project_media: pm, description: 'Custom Title'
    assert_equal 'Custom Title', pm.reload.title
    assert_equal media_filename('rails.png'), pm.reload.original_title
  end

  test "should get report information" do
    pm = create_project_media
    data = {
      title: 'Report text title',
      text: 'Report text content',
      headline: 'Visual card title',
      description: 'Visual card content'
    }
    publish_report(pm, {}, nil, data)
    pm = ProjectMedia.find(pm.id).reload
    assert_equal 'Report text title', pm.report_text_title
    assert_equal 'Report text content', pm.report_text_content
    assert_equal 'Visual card title', pm.report_visual_card_title
    assert_equal 'Visual card content', pm.report_visual_card_content
  end

  test "should get extracted text" do
    pm = create_project_media
    assert_kind_of String, pm.extracted_text
  end

  test "should validate archived value" do
    assert_difference 'ProjectMedia.count' do
      create_project_media archived: CheckArchivedFlags::FlagCodes::SPAM
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media archived: { main: 90 }
    end
  end

  test "should validate channel value" do
    # validate channel create (should be in allowed values)
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media channel: { main: 90 }
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media channel: { main: '90' }
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media channel: { others: [90] }
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media channel: { main: CheckChannels::ChannelCodes::MANUAL, others: [90] }
    end
    pm = nil
    assert_difference 'ProjectMedia.count' do
      pm = create_project_media channel: { main: CheckChannels::ChannelCodes::WHATSAPP }
    end
    # validate channel update (should not update existing value)
    assert_raises ActiveRecord::RecordInvalid do
      pm.channel = { main: CheckChannels::ChannelCodes::MESSENGER }
      pm.save!
    end
    assert_raises ActiveRecord::RecordInvalid do
      pm.channel = { others: [90] }
      pm.save!
    end
    assert_nothing_raised do
      pm.channel = { main: CheckChannels::ChannelCodes::WHATSAPP, others: [main: CheckChannels::ChannelCodes::MESSENGER]}
      pm.save!
    end
    # Set channel with default value MANUAL
    pm2 = create_project_media
    data = { "main" => CheckChannels::ChannelCodes::MANUAL }
    assert_equal data, pm2.channel
    # Set channel with API if ApiKey exists
    a = create_api_key
    ApiKey.current = a
    pm3 = create_project_media channel: nil
    data = { "main" => CheckChannels::ChannelCodes::API }
    assert_equal data, pm3.channel
    ApiKey.current = nil
  end

  test "should not create duplicated media with for the same uploaded file" do
    team = create_team
    team2 = create_team
    {
      UploadedVideo: 'rails.mp4',
      UploadedImage: 'rails.png',
      UploadedAudio: 'rails.mp3'
    }.each_pair do |media_type, filename|
      # first time the video is added creates a new media
      medias_count = media_type.to_s.constantize.count
      assert_difference 'ProjectMedia.count', 1 do
        pm = ProjectMedia.new media_type: media_type.to_s, team: team
        File.open(File.join(Rails.root, 'test', 'data', filename)) do |f|
          pm.file = f
          pm.save!
        end
      end
      assert_equal medias_count + 1, media_type.to_s.constantize.count

      # second time the video is added should not create new media
      medias_count = media_type.to_s.constantize.count
      assert_difference 'ProjectMedia.count', 1 do
        pm = ProjectMedia.new media_type: media_type.to_s, team: team2
        File.open(File.join(Rails.root, 'test', 'data', filename)) do |f|
          pm.file = f
          pm.save!
        end
      end
      assert_equal medias_count, media_type.to_s.constantize.count
    end
  end

  test "should run callbacks for bulk-update status" do
    ProjectMedia.stubs(:clear_caches).returns(nil)
    setup_elasticsearch
    t = create_team
    create_tag_text text: 'test', team_id: t.id
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "status_is",
                "rule_value": "verified"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "test"
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    with_current_user_and_team(u, t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      publish_report(pm)
      pm_status = pm.last_status
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      sleep 2
      ids = [pm.id, pm2.id, pm3.id]
      updates = { action: 'update_status', params: { status: 'verified' }.to_json }
      Sidekiq::Testing.inline! do
        ProjectMedia.bulk_update(ids, updates, t)
        sleep 2
        # Verify nothing happens for published reports
        assert_equal pm_status, pm.reload.last_status
        result = $repository.find(get_es_id(pm))
        assert_equal pm_status, result['verification_status']
        # Verify rules callback
        assert_equal ['test'], pm2.get_annotations('tag').map(&:load).map(&:tag_text)
        assert_equal ['test'], pm3.get_annotations('tag').map(&:load).map(&:tag_text)
        # Verify ES index
        result = $repository.find(get_es_id(pm2))
        assert_equal 'verified', result['verification_status']
        result = $repository.find(get_es_id(pm3))
        assert_equal 'verified', result['verification_status']
      end
    end
    ProjectMedia.unstub(:clear_caches)
  end

  test "should cache picture and creator name" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      u = create_user
      pm = create_project_media channel: { main: CheckChannels::ChannelCodes::MANUAL }, user: u
      # picture
      assert_queries(0, '=') { assert_equal('', pm.picture) }
      assert_queries(0, '>') { assert_equal('', pm.picture(true)) }
      # creator name
      assert_queries(0, '=') { assert_equal(u.name, pm.creator_name) }
      assert_queries(0, '>') { assert_equal(u.name, pm.creator_name(true)) }
    end
  end
end