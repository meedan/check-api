require_relative '../test_helper'

class ProjectMedia3Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
  end

  test "should restore and confirm item if not super admin" do
    setup_elasticsearch
    t = create_team
    p = create_project team: t
    p3 = create_project team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin', is_admin: false
    Sidekiq::Testing.inline! do
      # test restore
      pm = create_project_media project: p, disable_es_callbacks: false, archived: CheckArchivedFlags::FlagCodes::TRASHED
      sleep 1
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p.id, result
      assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.archived
      with_current_user_and_team(u, t) do
        pm.archived = CheckArchivedFlags::FlagCodes::NONE
        pm.disable_es_callbacks = false
        pm.project_id = p3.id
        pm.save!
      end
      pm = pm.reload
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived
      assert_equal p3.id, pm.project_id
      sleep 1
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p3.id, result
      # test confirm
      pm = create_project_media project: p, disable_es_callbacks: false, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED
      sleep 1
      assert_equal p.id, pm.project_id
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p.id, result
      assert_equal CheckArchivedFlags::FlagCodes::UNCONFIRMED, pm.archived
      with_current_user_and_team(u, t) do
        pm.archived = CheckArchivedFlags::FlagCodes::NONE
        pm.disable_es_callbacks = false
        pm.project_id = p3.id
        pm.save!
      end
      pm = pm.reload
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived
      assert_equal p3.id, pm.project_id
      sleep 1
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p3.id, result
    end
  end

  test "should set media type for links" do
    l = create_link
    pm = create_project_media url: l.url
    pm.send :set_media_type
    assert_equal 'Link', pm.media_type
  end

  test "should create link and account using team pender key" do
    t = create_team
    p = create_project(team: t)
    Team.stubs(:current).returns(t)

    url1 = random_url
    author_url1 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url1 }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => url1, "type" => "item", "title" => "Default token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Default token", "author_name" => 'Author with default token'}})

    url2 = random_url
    author_url2 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url2 }, 'specific_token').returns({"type" => "media","data" => {"url" => url2, "type" => "item", "title" => "Specific token", "author_url" => author_url2}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url2 }, 'specific_token').returns({"type" => "media","data" => {"url" => author_url2, "type" => "profile", "title" => "Specific token", "author_name" => 'Author with specific token'}})

    pm = ProjectMedia.create url: url1
    assert_equal 'Default token', ProjectMedia.find(pm.id).media.metadata['title']
    assert_equal 'Author with default token', ProjectMedia.find(pm.id).media.account.metadata['author_name']

    t.set_pender_key = 'specific_token'; t.save!

    pm = ProjectMedia.create! url: url2
    assert_equal 'Specific token', ProjectMedia.find(pm.id).media.metadata['title']
    assert_equal 'Author with specific token', ProjectMedia.find(pm.id).media.account.metadata['author_name']

    Team.unstub(:current)
    PenderClient::Request.unstub(:get_medias)
  end

  test "should refresh using team pender key" do
    t = create_team
    l = create_link
    Team.stubs(:current).returns(t)
    pm = create_project_media media: l, project: create_project(team: t)

    author_url1 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: l.url, refresh: '1' }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => l.url, "type" => "item", "title" => "Default token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Default token", "author_name" => 'Author with default token'}})

    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: l.url, refresh: '1' }, 'specific_token').returns({"type" => "media","data" => {"url" => l.url, "type" => "item", "title" => "Specific token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, 'specific_token').returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Author with specific token", "author_name" => 'Author with specific token'}})

    assert pm.media.metadata['title'].blank?

    pm.refresh_media = true
    pm.save!
    assert_equal 'Default token', ProjectMedia.find(pm.id).media.metadata['title']

    t.set_pender_key = 'specific_token'; t.save!
    pm = ProjectMedia.find(pm.id)
    pm.refresh_media = true; pm.save!
    assert_equal 'Specific token', ProjectMedia.find(pm.id).media.metadata['title']

    Team.unstub(:current)
    PenderClient::Request.unstub(:get_medias)
  end

  test "should not replace one project media by another if not from the same team" do
    old = create_project_media team: create_team, media: Blank.create!
    new = create_project_media team: create_team
    assert_raises RuntimeError do
      old.replace_by(new)
    end
  end

  test "should not replace one project media by another if media is not blank" do
    t = create_team
    old = create_project_media team: t
    new = create_project_media team: t
    assert_raises RuntimeError do
      old.replace_by(new)
    end
  end

  test "should replace a blank project media by another project media" do
    setup_elasticsearch
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u2
    at = create_annotation_type annotation_type: 'task_response_single_choice', label: 'Task'
    ft1 = create_field_type field_type: 'single_choice', label: 'Single Choice'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    tag_a = create_tag_text team_id: t.id
    tag_b = create_tag_text team_id: t.id
    tag_c = create_tag_text team_id: t.id
    tt = create_team_task team_id: t.id, task_type: 'single_choice', options: [{ label: 'Foo'}, { label: 'Faa' }]
    tt2 = create_team_task team_id: t.id, task_type: 'single_choice', options: [{ label: 'Optiona a'}, { label: 'Option b' }]
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      RequestStore.store[:skip_clear_cache] = true
      old = create_project_media team: t, media: Blank.create!, channel: { main: CheckChannels::ChannelCodes::FETCH }, disable_es_callbacks: false
      old_r = publish_report(old)
      old_s = old.last_status_obj
      new = create_project_media team: t, media: create_uploaded_video, disable_es_callbacks: false
      new_r = publish_report(new)
      new_s = new.last_status_obj
      old_tag_a = create_tag tag: tag_a.id, annotated: old
      old_tag_b = create_tag tag: tag_b.id, annotated: old
      new_tag_a = create_tag tag: tag_a.id, annotated: new
      new_tag_c = create_tag tag: tag_c.id, annotated: new
      # add task response
      new_tt = new.annotations('task').select{|t| t.team_task_id == tt.id}.last
      new_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_task: 'Foo' }.to_json }.to_json
      new_tt.save!
      new_tt2 = new.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      # add comments
      old_c = create_comment annotated: old
      new_c = create_comment annotated: new
      # assign to
      s = new.last_verification_status_obj
      s = Dynamic.find(s.id)
      s.assigned_to_ids = u2.id.to_s
      s.save!
      old.replace_by(new)
      assert_nil ProjectMedia.find_by_id(old.id)
      assert_nil Annotation.find_by_id(new_s.id)
      assert_nil Annotation.find_by_id(new_r.id)
      assert_equal old_r, new.get_dynamic_annotation('report_design')
      assert_equal old_s, new.get_dynamic_annotation('verification_status')
      new = new.reload
      assert_equal 'Import', new.creator_name
      data = { "main" => CheckChannels::ChannelCodes::FETCH }
      assert_equal data, new.channel
      assert_equal 3, new.annotations('tag').count
      assert_equal 2, new.annotations('comment').count
      # Verify ES
      result = $repository.find(get_es_id(new))
      assert_equal [CheckChannels::ChannelCodes::FETCH], result['channel']
      assert_equal [old_c.id, new_c.id], result['comments'].collect{ |c| c['id'] }.sort
      assert_equal [new_tag_a.id, new_tag_c.id, old_tag_b.id].sort, result['tags'].collect{ |tag| tag['id'] }.sort
      assert_equal [new_tt.id, new_tt2.id].sort, result['task_responses'].collect{ |task| task['id'] }.sort
      assert_equal [u2.id], result['assigned_user_ids']
    end
  end

  test "should create metrics annotation after create a project media" do
    create_annotation_type_and_fields('Metrics', { 'Data' => ['JSON', false] })
    url = 'https://twitter.com/meedan/status/1321600654750613505'
    response = {"type" => "media","data" => {"url" => url, "type" => "item", "metrics" => {"facebook"=> {"reaction_count" => 2, "comment_count" => 5, "share_count" => 10, "comment_plugin_count" => 0 }}}}

    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url }, CheckConfig.get('pender_key')).returns(response)
    pm = create_project_media media: nil, url: url
    assert_equal response['data']['metrics'], JSON.parse(pm.get_annotations('metrics').last.load.get_field_value('metrics_data'))
    PenderClient::Request.unstub(:get_medias)
  end

  test "should cache metadata value" do
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    t = create_team
    tt = create_team_task fieldset: 'metadata', team_id: t.id
    pm = create_project_media team: t
    m = pm.get_annotations('task').last.load
    value = random_string
    m.response = { annotation_type: 'task_response', set_fields: { response_test: value }.to_json }.to_json
    m.save!
    assert_queries(0, '=') do
      assert_equal value, pm.send("task_value_#{tt.id}")
    end
    assert_not_nil Rails.cache.read("project_media:task_value:#{pm.id}:#{tt.id}")
    assert_not_nil pm.reload.task_value(tt.id)
    d = m.reload.first_response_obj
    d.destroy!
    assert_nil Rails.cache.read("project_media:task_value:#{pm.id}:#{tt.id}")
    assert_nil pm.reload.task_value(tt.id)
  end

  test "should return item columns values" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      at = create_annotation_type annotation_type: 'task_response'
      create_field_instance annotation_type_object: at, name: 'response_test'
      t = create_team
      tt1 = create_team_task fieldset: 'metadata', team_id: t.id
      tt2 = create_team_task fieldset: 'metadata', team_id: t.id
      t.list_columns = ["task_value_#{tt1.id}", "task_value_#{tt2.id}"]
      t.save!
      pm = create_project_media team: t.reload
      m = pm.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
      m.response = { annotation_type: 'task_response', set_fields: { response_test: 'Foo Value' }.to_json }.to_json
      m.save!
      m = pm.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
      m.response = { annotation_type: 'task_response', set_fields: { response_test: 'Bar Value' }.to_json }.to_json
      m.save!
      pm.team
      # The only SQL query should be to get the team tasks
      assert_queries(1, '=') do
        values = pm.list_columns_values
        assert_equal 2, values.size
        assert_equal 'Foo Value', values["task_value_#{tt1.id}"]
        assert_equal 'Bar Value', values["task_value_#{tt2.id}"]
      end
      pm2 = create_project_media
      pm2.team
      pm2.media
      # The only SQL query should be to get the team tasks
      assert_queries(1, '=') do
        assert_equal 8, pm2.list_columns_values.keys.size
      end
    end
  end

  test "should return error if method does not exist" do
    pm = create_project_media
    assert_raises NoMethodError do
      pm.send(random_string)
    end
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
    pm = create_project_media
    assert_queries(0, '=') { assert_equal 'Link', pm.type_of_media }
    Rails.cache.clear
    assert_queries(1, '=') { assert_equal 'Link', pm.type_of_media }
    assert_queries(0, '=') { assert_equal 'Link', pm.type_of_media }
    sleep 1
    es = $repository.find(get_es_id(pm))
    assert_equal Media.types.index(pm.type_of_media), es['type_of_media']
  end

  test "should cache project title" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      t = create_team
      p1 = create_project title: 'Foo', team: t
      p2 = create_project title: 'Bar', team: t
      pm = create_project_media team: t
      default_folder = t.default_folder
      assert_queries(0, '=') { assert_equal default_folder.title, pm.folder }
      pm.project_id = p1.id
      pm.save!
      assert_queries(0, '=') { assert_equal 'Foo', pm.folder }
      p1.title = 'Test'
      p1.save!
      assert_queries(0, '=') { assert_equal 'Test', pm.folder }
      pm.project_id = p2.id
      pm.save!
      assert_queries(0, '=') { assert_equal 'Bar', pm.folder }
      assert_equal p2.id, pm.reload.project_id
      p2.destroy!
      assert_equal t.default_folder.id, pm.reload.project_id
      assert_queries(0, '=') { assert_equal default_folder.title, pm.folder }
    end
  end

  test "should get original title for uploaded files" do
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media media: create_uploaded_image
    create_claim_description project_media: pm, description: 'Custom Title'
    assert_equal 'Custom Title', pm.reload.title
    assert_equal media_filename('rails.png'), pm.reload.original_title
  end

  test "should move secondary item to same main item project" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      t = create_team
      p = create_project team: t
      p2 = create_project team: t
      pm = create_project_media project: p
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      assert_equal p.title, Rails.cache.read("check_cached_field:ProjectMedia:#{pm.id}:folder")
      create_relationship source_id: pm.id, target_id: pm2.id
      create_relationship source_id: pm.id, target_id: pm3.id
      pm.project_id = p2.id
      pm.save!
      assert_equal p2.id, pm2.reload.project_id
      assert_equal p2.id, pm3.reload.project_id
      # verify cached folder value
      assert_equal p2.title, Rails.cache.read("check_cached_field:ProjectMedia:#{pm.id}:folder")
      assert_equal p2.title, Rails.cache.read("check_cached_field:ProjectMedia:#{pm2.id}:folder")
      assert_equal p2.title, Rails.cache.read("check_cached_field:ProjectMedia:#{pm3.id}:folder")
    end
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
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
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
          "action_definition": "move_to_project",
          "action_value": p.id.to_s
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
        assert_equal t.default_folder.id, pm.reload.project_id
        assert_equal p.id, pm2.reload.project_id
        assert_equal p.id, pm3.reload.project_id
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

  test "should get creator name based on channel" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      u = create_user
      pm = create_project_media user: u
      assert_equal pm.creator_name, u.name
      pm2 = create_project_media user: u, channel: { main: CheckChannels::ChannelCodes::WHATSAPP }
      assert_equal pm2.creator_name, 'Tipline'
      pm3 = create_project_media user: u, channel: { main: CheckChannels::ChannelCodes::FETCH }
      assert_equal pm3.creator_name, 'Import'
      # update cache based on user update
      u.name = 'update name'
      u.save!
      assert_equal pm.creator_name, 'update name'
      assert_equal pm.creator_name(true), 'update name'
      assert_equal pm2.creator_name, 'Tipline'
      assert_equal pm2.creator_name(true), 'Tipline'
      assert_equal pm3.creator_name, 'Import'
      assert_equal pm3.creator_name(true), 'Import'
      User.delete_check_user(u)
      assert_equal pm.creator_name, 'Anonymous'
      assert_equal pm.reload.creator_name(true), 'Anonymous'
      assert_equal pm2.creator_name, 'Tipline'
      assert_equal pm2.creator_name(true), 'Tipline'
      assert_equal pm3.creator_name, 'Import'
      assert_equal pm3.creator_name(true), 'Import'
    end
  end

  test "should create blank item" do
    assert_difference 'ProjectMedia.count' do
      assert_difference 'Blank.count' do
        ProjectMedia.create! media_type: 'Blank', team: create_team
      end
    end
  end

  test "should convert old hash" do
    t = create_team
    pm = create_project_media team: t
    Team.any_instance.stubs(:settings).returns(ActionController::Parameters.new({ media_verification_statuses: { statuses: [] } }))
    assert_nothing_raised do
      pm.custom_statuses
    end
    Team.any_instance.unstub(:settings)
  end

  test "should assign item to default project if project not set" do
    t = create_team
    pm = create_project_media team: t
    assert_equal pm.project, t.default_folder
  end

  test "should detach similar items when trash parent item" do
    setup_elasticsearch
    RequestStore.store[:skip_delete_for_ever] = true
    t = create_team
    default_folder = t.default_folder
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    pm1_c = create_project_media project: p, disable_es_callbacks: false
    pm1_s = create_project_media project: p, disable_es_callbacks: false
    pm2_s = create_project_media project: p, disable_es_callbacks: false
    r = create_relationship source: pm, target: pm1_c, relationship_type: Relationship.confirmed_type
    r2 = create_relationship source: pm, target: pm1_s, relationship_type: Relationship.suggested_type
    r3 = create_relationship source: pm, target: pm2_s, relationship_type: Relationship.suggested_type
    assert_difference 'Relationship.count', -2 do
      pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
      pm.save!
    end
    assert_raises ActiveRecord::RecordNotFound do
      r2.reload
    end
    assert_raises ActiveRecord::RecordNotFound do
      r3.reload
    end
    pm1_s = pm1_s.reload; pm2_s.reload
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm1_c.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm1_s.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm2_s.archived
    assert_equal p.id, pm1_s.project_id
    assert_equal p.id, pm2_s.project_id
    # Verify ES
    result = $repository.find(get_es_id(pm1_c))
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, result['archived']
    result = $repository.find(get_es_id(pm1_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
    assert_equal p.id, result['project_id']
    result = $repository.find(get_es_id(pm2_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
    assert_equal p.id, result['project_id']
  end

  test "should detach similar items when spam parent item" do
    setup_elasticsearch
    RequestStore.store[:skip_delete_for_ever] = true
    t = create_team
    default_folder = t.default_folder
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    pm1_c = create_project_media project: p, disable_es_callbacks: false
    pm1_s = create_project_media project: p, disable_es_callbacks: false
    pm2_s = create_project_media project: p, disable_es_callbacks: false
    r = create_relationship source: pm, target: pm1_c, relationship_type: Relationship.confirmed_type
    r2 = create_relationship source: pm, target: pm1_s, relationship_type: Relationship.suggested_type
    r3 = create_relationship source: pm, target: pm2_s, relationship_type: Relationship.suggested_type
    assert_difference 'Relationship.count', -2 do
      pm.archived = CheckArchivedFlags::FlagCodes::SPAM
      pm.save!
    end
    assert_raises ActiveRecord::RecordNotFound do
      r2.reload
    end
    assert_raises ActiveRecord::RecordNotFound do
      r3.reload
    end
    pm1_s = pm1_s.reload; pm2_s.reload
    assert_equal CheckArchivedFlags::FlagCodes::SPAM, pm1_c.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm1_s.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm2_s.archived
    assert_equal p.id, pm1_s.project_id
    assert_equal p.id, pm2_s.project_id
    # Verify ES
    result = $repository.find(get_es_id(pm1_c))
    assert_equal CheckArchivedFlags::FlagCodes::SPAM, result['archived']
    result = $repository.find(get_es_id(pm1_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
    assert_equal p.id, result['project_id']
    result = $repository.find(get_es_id(pm2_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
    assert_equal p.id, result['project_id']
  end

  test "should get cluster size" do
    pm = create_project_media
    assert_nil pm.reload.cluster
    c = create_cluster
    c.project_medias << pm
    assert_equal 1, pm.reload.cluster.size
    c.project_medias << create_project_media
    assert_equal 2, pm.reload.cluster.size
  end

  test "should get cluster teams" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch
    t1 = create_team
    t2 = create_team
    pm1 = create_project_media team: t1
    assert_nil pm1.cluster
    c = create_cluster project_media: pm1
    c.project_medias << pm1
    assert_equal [t1.name], pm1.cluster.team_names.values
    assert_equal [t1.id], pm1.cluster.team_names.keys
    sleep 2
    id = get_es_id(pm1)
    es = $repository.find(id)
    assert_equal [t1.id], es['cluster_teams']
    pm2 = create_project_media team: t2
    c.project_medias << pm2
    sleep 2
    assert_equal [t1.name, t2.name].sort, pm1.cluster.team_names.values.sort
    assert_equal [t1.id, t2.id].sort, pm1.cluster.team_names.keys.sort
    es = $repository.find(id)
    assert_equal [t1.id, t2.id], es['cluster_teams']
  end


end