require_relative '../test_helper'

class ProjectMedia4Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
  end

  test "should get project id for migration" do
    p = create_project
    mapping = Hash.new
    pm = ProjectMedia.new
    assert_nil pm.send(:project_id_callback, 1, mapping)
    mapping[1] = p.id
    assert_equal p.id, pm.send(:project_id_callback, 1, mapping)
  end

  test "should set annotation" do
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    lt = create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'translation', label: 'Translation'
    create_field_instance annotation_type_object: at, name: 'translation_text', label: 'Translation Text', field_type_object: ft, optional: false
    create_field_instance annotation_type_object: at, name: 'translation_note', label: 'Translation Note', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'translation_language', label: 'Translation Language', field_type_object: lt, optional: false
    assert_equal 0, Annotation.where(annotation_type: 'translation').count
    create_project_media set_annotation: { annotation_type: 'translation', set_fields: { 'translation_text' => 'Foo', 'translation_note' => 'Bar', 'translation_language' => 'pt' }.to_json }.to_json
    assert_equal 1, Annotation.where(annotation_type: 'translation').count
  end

  test "should have reference to search team object" do
    pm = create_project_media
    assert_kind_of CheckSearch, pm.check_search_team
  end

  test "should get dynamic annotation by type" do
    create_annotation_type annotation_type: 'foo'
    create_annotation_type annotation_type: 'bar'
    pm = create_project_media
    d1 = create_dynamic_annotation annotation_type: 'foo', annotated: pm
    d2 = create_dynamic_annotation annotation_type: 'bar', annotated: pm
    assert_equal d1, pm.get_dynamic_annotation('foo')
    assert_equal d2, pm.get_dynamic_annotation('bar')
  end

  test "should get report type" do
    c = create_claim_media
    l = create_link

    m = create_project_media media: c
    assert_equal 'claim', m.report_type
    m = create_project_media media: l
    assert_equal 'link', m.report_type
  end

  test "should delete project media" do
    t = create_team
    u = create_user
    u2 = create_user
    tu = create_team_user team: t, user: u, role: 'admin'
    tu = create_team_user team: t, user: u2
    pm = create_project_media team: t, quote: 'Claim', user: u2
    at = create_annotation_type annotation_type: 'test'
    ft = create_field_type
    fi = create_field_instance name: 'test', field_type_object: ft, annotation_type_object: at
    a = create_dynamic_annotation annotator: u2, annotated: pm, annotation_type: 'test', set_fields: { test: 'Test' }.to_json
    RequestStore.store[:disable_es_callbacks] = true
    with_current_user_and_team(u, t) do
      pm.destroy
    end
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should have Pender embeddable URL" do
    RequestStore[:request] = nil
    t = create_team
    pm = create_project_media team: t
    stub_configs({ 'pender_url' => 'https://pender.fake' }) do
      assert_equal CheckConfig.get('pender_url') + '/api/medias.html?url=' + pm.full_url.to_s, pm.embed_url(false)
    end
    stub_configs({ 'pender_url' => 'https://pender.fake' }) do
      assert_match /#{CheckConfig.get('short_url_host')}/, pm.embed_url
    end
  end

  test "should have oEmbed endpoint" do
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media media: m
    assert_equal 'test media', pm.as_oembed[:title]
  end

  test "should have oEmbed URL" do
    RequestStore[:request] = nil
    t = create_team private: false
    p = create_project team: t
    pm = create_project_media project: p
    stub_configs({ 'checkdesk_base_url' => 'https://checkmedia.org' }) do
      assert_equal "https://checkmedia.org/api/project_medias/#{pm.id}/oembed", pm.oembed_url
    end

    t = create_team private: true
    p = create_project team: t
    pm = create_project_media project: p
    stub_configs({ 'checkdesk_base_url' => 'https://checkmedia.org' }) do
      assert_equal "https://checkmedia.org/api/project_medias/#{pm.id}/oembed", pm.oembed_url
    end
  end

  test "should get author name for oEmbed" do
    u = create_user name: 'Foo Bar'
    pm = create_project_media user: u
    assert_equal 'Foo Bar', pm.author_name
    pm.user = nil
    assert_equal '', pm.author_name
  end

  test "should get author URL for oEmbed" do
    url = 'http://twitter.com/test'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"profile"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_omniauth_user url: url, provider: 'twitter'
    pm = create_project_media user: u
    assert_equal url, pm.author_url
    pm.user = create_user
    assert_equal '', pm.author_url
    pm.user = nil
    assert_equal '', pm.author_url
  end

  test "should get author picture for oEmbed" do
    u = create_user
    pm = create_project_media user: u
    assert_match /^http/, pm.author_picture
  end

  test "should get author username for oEmbed" do
    u = create_user login: 'test'
    pm = create_project_media user: u
    assert_equal 'test', pm.author_username
    pm.user = nil
    assert_equal '', pm.author_username
  end

  test "should get author role for oEmbed" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'collaborator'
    pm = create_project_media team: t, user: u
    assert_equal 'collaborator', pm.author_role
    pm.user = create_user
    assert_equal 'none', pm.author_role
    pm.user = nil
    assert_equal 'none', pm.author_role
  end

  test "should get source URL for external link for oEmbed" do
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal url, pm.source_url
    c = create_claim_media
    pm = create_project_media media: c
    assert_match CheckConfig.get('checkdesk_client'), pm.source_url
  end

  test "should get completed tasks for oEmbed" do
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response'
    pm = create_project_media
    assert_equal [], pm.completed_tasks
    assert_equal 0, pm.completed_tasks_count
    t1 = create_task annotated: pm
    t1.response = { annotation_type: 'task_response', set_fields: { response: 'Test' }.to_json }.to_json
    t1.save!
    t2 = create_task annotated: pm
    assert_equal [t1], pm.completed_tasks
    assert_equal [t2], pm.open_tasks
    assert_equal 1, pm.completed_tasks_count
  end

  test "should get comments for oEmbed" do
    pm = create_project_media
    assert_equal [], pm.comments
    assert_equal 0, pm.comments_count
    c = create_comment annotated: pm
    assert_equal [c], pm.comments
    assert_equal 1, pm.comments_count
  end

  test "should get provider for oEmbed" do
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal 'Twitter', pm.provider
    c = create_claim_media
    pm = create_project_media media: c
    assert_equal 'Check', pm.provider
  end

  test "should get published time for oEmbed" do
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"1989-01-25 08:30:00"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal '25/01/1989', pm.published_at.strftime('%d/%m/%Y')
    c = create_claim_media
    pm = create_project_media media: c
    assert_nil pm.published_at
  end

  test "should get source author for oEmbed" do
    u = create_user name: 'Foo'
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","author_name":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l, user: u
    assert_equal 'Bar', pm.source_author[:author_name]
    c = create_claim_media
    pm = create_project_media media: c, user: u
    assert_equal 'Foo', pm.source_author[:author_name]
  end

  test "should render oEmbed HTML" do
    Sidekiq::Testing.inline! do
      pm = create_project_media
      PenderClient::Request.stubs(:get_medias)
      publish_report(pm, {}, nil, {
        use_visual_card: false,
        use_text_message: true,
        use_disclaimer: false,
        disclaimer: '',
        title: 'Title',
        text: '*This* _is_ a ~test~!',
        published_article_url: 'http://foo.bar'
      })
      PenderClient::Request.unstub(:get_medias)
      expected = File.read(File.join(Rails.root, 'test', 'data', "oembed-#{pm.default_project_media_status_type}.html")).gsub(/^\s+/m, '')
      actual = ProjectMedia.find(pm.id).html.gsub(/.*<body/m, '<body').gsub(/^\s+/m, '').gsub(/https?:\/\/[^:]*:3000/, 'http://check')
      assert_equal expected, actual
    end
  end

  test "should have metadata for oEmbed" do
    pm = create_project_media
    assert_kind_of String, pm.oembed_metadata
  end

  test "should clear caches when media is updated" do
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
    pm = create_project_media
    create_dynamic_annotation annotation_type: 'embed_code', annotated: pm
    u = create_user
    ProjectMedia.any_instance.unstub(:clear_caches)
    CcDeville.expects(:clear_cache_for_url).returns(nil).times(52)
    PenderClient::Request.expects(:get_medias).returns(nil).times(16)

    Sidekiq::Testing.inline! do
      create_comment annotated: pm, user: u
      create_task annotated: pm, user: u
    end

    CcDeville.unstub(:clear_cache_for_url)
    PenderClient::Request.unstub(:get_medias)
  end

  test "should respond to auto-tasks on creation" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_free_text', label: 'Note', field_type_object: ft1

    t = create_team
    p = create_project team: t
    create_team_task team_id: t.id, label: 'When?'
    Sidekiq::Testing.inline! do
      assert_difference 'Task.length', 1 do
        pm = create_project_media project: p, set_tasks_responses: { 'when' => 'Yesterday' }
        task = pm.annotations('task').last
        assert_equal 'Yesterday', task.first_response
      end
    end
  end

  test "should auto-response for Krzana report" do
    at = create_annotation_type annotation_type: 'task_response_geolocation', label: 'Task Response Geolocation'
    geotype = create_field_type field_type: 'geojson', label: 'GeoJSON'
    create_field_instance annotation_type_object: at, name: 'response_geolocation', field_type_object: geotype

    at = create_annotation_type annotation_type: 'task_response_datetime', label: 'Task Response Date Time'
    datetime = create_field_type field_type: 'datetime', label: 'Date Time'
    create_field_instance annotation_type_object: at, name: 'response_datetime', field_type_object: datetime

    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi2 = create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Note', field_type_object: ft1

    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    p3 = create_project team: t
    tt1 = create_team_task team_id: t.id, label: 'who?', task_type: 'free_text', mapping: { "type" => "free_text", "match" => "$.mentions[?(@['@type'] == 'Person')].name", "prefix" => "Suggested by Krzana: "}
    tt2 = create_team_task team_id: t.id, label: 'where?', task_type: 'geolocation', mapping: { "type" => "geolocation", "match" => "$.mentions[?(@['@type'] == 'Place')]", "prefix" => ""}
    tt3 = create_team_task team_id: t.id, label: 'when?', type: 'datetime', mapping: { "type" => "datetime", "match" => "dateCreated", "prefix" => ""}

    Sidekiq::Testing.inline! do
      pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
      # test empty json+ld
      url = 'http://test1.com'
      raw = {"json+ld": {}}
      response = {'type':'media','data': {'url': url, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      pm = create_project_media project: p, url: url
      t = Task.where(annotation_type: 'task', annotated_id: pm.id).select{ |t| t.team_task_id == tt1.id }.last
      assert_nil t.first_response

      # test with non exist value
      url1 = 'http://test11.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person" } ] } }
      response = {'type':'media','data': {'url': url1, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url1 } }).to_return(body: response)
      pm1 = create_project_media project: p, url: url1
      t = Task.where(annotation_type: 'task', annotated_id: pm1.id).select{ |t| t.team_task_id == tt1.id }.last
      assert_nil t.first_response

      # test with empty value
      url12 = 'http://test12.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person", "name": "" } ] } }
      response = {'type':'media','data': {'url': url12, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url12 } }).to_return(body: response)
      pm12 = create_project_media project: p, url: url12
      t = Task.where(annotation_type: 'task', annotated_id: pm12.id).select{ |t| t.team_task_id == tt1.id }.last
      assert_nil t.first_response

      # test with single selection
      url2 = 'http://test2.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person", "name": "first_name" } ] } }
      response = {'type':'media','data': {'url': url2, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: response)
      pm2 = create_project_media project: p, url: url2
      t = Task.where(annotation_type: 'task', annotated_id: pm2.id).select{ |t| t.team_task_id == tt1.id }.last
      assert_equal "Suggested by Krzana: first_name", t.first_response

      # test multiple selection (should get first one)
      url3 = 'http://test3.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person", "name": "first_name" }, { "@type": "Person", "name": "last_name" } ] } }
      response = {'type':'media','data': {'url': url3, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url3 } }).to_return(body: response)
      pm3 = create_project_media project: p, url: url3
      t = Task.where(annotation_type: 'task', annotated_id: pm3.id).select{ |t| t.team_task_id == tt1.id }.last
      assert_equal "Suggested by Krzana: first_name", t.first_response

      # test geolocation mapping
      url4 = 'http://test4.com'
      raw = { "json+ld": {
        "mentions": [ { "name": "Delimara Powerplant", "@type": "Place", "geo": { "latitude": 35.83020073454, "longitude": 14.55602645874 } } ]
      } }
      response = {'type':'media','data': {'url': url4, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url4 } }).to_return(body: response)
      pm4 = create_project_media project: p2, url: url4
      t = Task.where(annotation_type: 'task', annotated_id: pm4.id).select{ |t| t.team_task_id == tt2.id }.last
      # assert_not_nil t.first_response

      # test datetime mapping
      url5 = 'http://test5.com'
      raw = { "json+ld": { "dateCreated": "2017-08-30T14:22:28+00:00" } }
      response = {'type':'media','data': {'url': url5, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url5 } }).to_return(body: response)
      pm5 = create_project_media project: p3, url: url5
      t = Task.where(annotation_type: 'task', annotated_id: pm5.id).select{ |t| t.team_task_id == tt3.id }.last
      assert_not_nil t.first_response
    end
  end

  test "should expose conflict error from Pender" do
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"error","data":{"message":"Conflict","code":9}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response, status: 409)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response, status: 409)
    t = create_team
    pm = ProjectMedia.new
    pm.team = t
    pm.url = url
    pm.media_type = 'Link'
    assert_raises RuntimeError do
      pm.save!
      assert_equal PenderClient::ErrorCodes::DUPLICATED, pm.media.pender_error_code
    end
  end

  test "should not create project media under archived project" do
    p = create_project archived: CheckArchivedFlags::FlagCodes::TRASHED
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media project_id: p.id
    end
  end

  test "should archive" do
    pm = create_project_media
    assert_equal pm.archived, CheckArchivedFlags::FlagCodes::NONE
    pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm.save!
    assert_equal pm.reload.archived, CheckArchivedFlags::FlagCodes::TRASHED
  end

  test "should create annotation when is embedded for the first time" do
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
    pm = create_project_media
    assert_difference 'Annotation.where(annotation_type: "embed_code").count', 1 do
      pm.as_oembed
    end
    assert_no_difference 'Annotation.where(annotation_type: "embed_code").count' do
      pm.as_oembed
    end
  end

  test "should not crash if mapping value is invalid" do
    assert_nothing_raised do
      pm = ProjectMedia.new
      assert_nil pm.send(:mapping_value, 'foo', 'bar')
    end
  end

  test "should not crash if another user tries to update media" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u1, role: 'admin'
    create_team_user team: t, user: u2, role: 'admin'
    pm = nil

    with_current_user_and_team(u1, t) do
      pm = create_project_media team: t, user: u1
      pm = ProjectMedia.find(pm.id)
      info = { title: 'Title' }
      pm.analysis = info
      pm.save!
    end

    with_current_user_and_team(u2, t) do
      pm = ProjectMedia.find(pm.id)
      info = { title: 'Title' }
      pm.analysis = info
      pm.save!
    end
  end

  test "should get claim description only if it has been set" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      c = create_claim_media quote: 'Test'
      pm = create_project_media media: c
      assert_equal 'Test', pm.reload.description
      create_claim_description project_media: pm, description: 'Test 2'
      assert_equal 'Test 2', pm.reload.description
    end
  end

  test "should create pender_archive annotation for link" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    p = create_project team: t
    pm = create_project_media media: l, team: t, project_id: p.id
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should not create pender_archive annotation when media is not a link" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    c = create_claim_media
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    p = create_project team: t
    pm = create_project_media media: c, project: p
    assert_no_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_no_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should not create pender_archive annotation when there is no annotation type" do
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p
    assert_no_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_no_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should create pender_archive annotation using information from pender_embed" do
    Link.any_instance.stubs(:pender_embed).returns(OpenStruct.new({ data: { embed: { screenshot_taken: 1, 'archives' => {} }.to_json }.with_indifferent_access }))
    Media.any_instance.stubs(:pender_embed).returns(OpenStruct.new({ data: { embed: { screenshot_taken: 1, 'archives' => {} }.to_json }.with_indifferent_access }))
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
    Link.any_instance.unstub(:pender_embed)
    Media.any_instance.unstub(:pender_embed)
  end

  test "should create pender_archive annotation using information from pender_data" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    Link.any_instance.stubs(:pender_data).returns({ screenshot_taken: 1, 'archives' => {} })
    Link.any_instance.stubs(:pender_embed).raises(RuntimeError)
    pm = create_project_media media: l, team: t
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
    Link.any_instance.unstub(:pender_data)
    Link.any_instance.unstub(:pender_embed)
  end

  test "should update media account when change author_url" do
    setup_elasticsearch
    u = create_user is_admin: true
    t = create_team
    create_team_user user: u, team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://www.facebook.com/meedan/posts/123456'
    author_url = 'http://facebook.com/123456'
    author_normal_url = 'http://www.facebook.com/meedan'
    author2_url = 'http://facebook.com/789123'
    author2_normal_url = 'http://www.facebook.com/meedan2'

    data = { url: url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    data = { url: url, author_url: author2_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    data = { url: author2_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'NewFoo', description: 'NewBar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author2_url } }).to_return(body: response)


    m = create_media team: t, url: url, account: nil, account_id: nil
    a = m.account
    p = create_project team: t
    Sidekiq::Testing.inline! do
      pm = create_project_media media: m, project: p, disable_es_callbacks: false
      sleep 2
      pm = ProjectMedia.find(pm.id)
      with_current_user_and_team(u, t) do
        pm.refresh_media = true
        sleep 2
      end
      new_account = m.reload.account
      assert_not_equal a, new_account
      assert_nil Account.where(id: a.id).last
      result = $repository.find(get_es_id(pm))
      assert_equal 1, result['accounts'].size
      assert_equal result['accounts'].first['id'], new_account.id
    end
  end

  test "should update elasticsearch parent_id field" do
    setup_elasticsearch
    t = create_team
    s1 = create_project_media team: t, disable_es_callbacks: false
    s2 = create_project_media team: t, disable_es_callbacks: false
    s3 = create_project_media team: t, disable_es_callbacks: false
    t1 = create_project_media team: t, disable_es_callbacks: false
    t2 = create_project_media team: t, disable_es_callbacks: false
    t3 = create_project_media team: t, disable_es_callbacks: false
    r1 = create_relationship source_id: s1.id, target_id: t1.id, disable_es_callbacks: false
    r2 = create_relationship source_id: s2.id, target_id: t2.id, relationship_type: Relationship.confirmed_type, disable_es_callbacks: false
    r3 = create_relationship source_id: s3.id, target_id: t3.id, relationship_type: Relationship.suggested_type, disable_es_callbacks: false
    sleep 2
    t1_es = $repository.find(get_es_id(t1))
    assert_equal t1.id, t1_es['parent_id']
    t2_es = $repository.find(get_es_id(t2))
    assert_equal s2.id, t2_es['parent_id']
    t3_es = $repository.find(get_es_id(t3))
    assert_equal t3.id, t3_es['parent_id']
    r2.destroy!
    sleep 2
    t2_es = $repository.find(get_es_id(t2))
    assert_equal t2.id, t2_es['parent_id']
  end

  test "should validate media source" do
    t = create_team
    t2 = create_team
    s = create_source team: t
    s2 = create_source team: t2
    pm = nil
    assert_difference 'ProjectMedia.count', 2 do
      create_project_media team: t
      pm = create_project_media team: t, source_id: s.id
    end
    assert_raises ActiveRecord::RecordInvalid do
      pm.source_id = s2.id
      pm.save!
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media team: t, source_id: s2.id, skip_autocreate_source: false
    end
  end

  test "should assign media source using account" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t2, user: u, role: 'admin'
    m = nil
    s = nil
    with_current_user_and_team(u, t) do
      m = create_valid_media
      s = m.account.sources.first
      assert_equal t.id, s.team_id
      pm = create_project_media media: m, team: t, skip_autocreate_source: false
      assert_equal s.id, pm.source_id
    end
    pm = create_project_media media: m, team: t2, skip_autocreate_source: false
    s2 = pm.source
    assert_not_nil pm.source_id
    assert_not_equal s.id, s2.id
    assert_equal t2.id, s2.team_id
    assert_equal m.account, s2.accounts.first
  end

  test "should create media when normalized URL exists" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'

    url = 'https://www.facebook.com/Ma3komMona/videos/695409680623722'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    t = create_team
    l = create_link team: t, url: url
    pm = create_project_media media: l

    url = 'https://www.facebook.com/Ma3komMona/videos/vb.268809099950451/695409680623722/?type=3&theater'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"https://www.facebook.com/Ma3komMona/videos/695409680623722","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_difference 'ProjectMedia.count' do
      pm = ProjectMedia.new
      pm.url = url
      pm.media_type = 'Link'
      pm.team = t
      pm.save!
    end
  end

  test "should complete media if there are pending tasks" do
    pm = create_project_media
    s = pm.last_verification_status_obj
    create_task annotated: pm, required: true
    assert_equal 'undetermined', s.reload.get_field('verification_status_status').status
    assert_nothing_raised do
      s.status = 'verified'
      s.save!
    end
  end

  test "should get account from author URL" do
    s = create_source
    pm = create_project_media
    assert_nothing_raised do
      pm.send :account_from_author_url, @url, s
    end
  end

  test "should not move media to active status if status is locked" do
    pm = create_project_media
    assert_equal 'undetermined', pm.last_verification_status
    s = pm.last_verification_status_obj
    s.locked = true
    s.save!
    create_task annotated: pm, disable_update_status: false
    assert_equal 'undetermined', pm.reload.last_verification_status
  end

  test "should have status permission" do
    u = create_user
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      permissions = JSON.parse(pm.permissions)
      assert permissions.has_key?('update Status')
    end
  end

  test "should not crash if media does not have status" do
    pm = create_project_media
    Annotation.delete_all
    assert_nothing_raised do
      assert_nil pm.last_verification_status_obj
    end
  end

  test "should have relationships and parent and children reports" do
    p = create_project
    s1 = create_project_media project: p
    s2 = create_project_media project: p
    t1 = create_project_media project: p
    t2 = create_project_media project: p
    create_project_media project: p
    create_relationship source_id: s1.id, target_id: t1.id
    create_relationship source_id: s2.id, target_id: t2.id
    assert_equal [t1], s1.targets
    assert_equal [t2], s2.targets
    assert_equal [s1], t1.sources
    assert_equal [s2], t2.sources
  end

  test "should return related" do
    pm = create_project_media
    pm2 = create_project_media
    assert_nil pm.related_to
    pm.related_to_id = pm2.id
    assert_equal pm2, pm.related_to
  end

  test "should include extra attributes in serialized object" do
    pm = create_project_media
    pm.related_to_id = 1
    dump = YAML::dump(pm)
    assert_match /related_to_id/, dump
  end

  test "should skip screenshot archiver" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = false
    tbi.save!
    pm = create_project_media project: create_project(team: t), media: l
    assert pm.should_skip_create_archive_annotation?('pender_archive')
  end

  test "should destroy project media when associated_id on version is not valid" do
    with_versioning do
      m = create_valid_media
      t = create_team
      p = create_project team: t
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      pm = nil
      with_current_user_and_team(u, t) do
        pm = create_project_media project: p, media: m, user: u
        pm.source_id = create_source(team_id: t.id).id
        pm.save
        assert_equal 3, pm.versions.count
      end
      version = pm.versions.last
      version.update_attribute('associated_id', 100)

      assert_nothing_raised do
        pm.destroy
      end
    end
  end

  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5ca644ecf023ba001260e71d
  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5ca4faa1f023ba001260dbae
  test "should create claim with Indian characters" do
    str1 = "_Buy Redmi Note 5 Pro Mobile at *2999 Rs* (95�\u0000off) in Flash Sale._\r\n\r\n*Grab this offer now, Deal valid only for First 1,000 Customers. Visit here to Buy-* http://sndeals.win/"
    str2 = "*प्रधानमंत्री छात्रवृति योजना 2019*\n\n*Scholarship Form for 10th or 12th Open Now*\n\n*Scholarship Amount*\n1.50-60�\u0000- Rs. 5000/-\n2.60-80�\u0000- Rs. 10000/-\n3.Above 80�\u0000- Rs. 25000/-\n\n*सभी 10th और 12th के बच्चो व उनके अभिभावकों को ये SMS भेजे ताकि सभी बच्चे इस योजना का लाभ ले सके*\n\n*Click Here for Apply:*\nhttps://bit.ly/2l71tWl"
    [str1, str2].each do |str|
      assert_difference 'ProjectMedia.count' do
        m = create_claim_media quote: str
        create_project_media media: m
      end
    end
  end

  test "should not create project media with unsafe URL" do
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    url = 'http://unsafe.com/'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"error","data":{"code":12}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    assert_raises RuntimeError do
      pm = create_project_media media: nil, url: url
      assert_equal 12, pm.media.pender_error_code
    end
  end

  test "should get metadata" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'title' => 'Media Title', 'description' => 'Media Description' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal 'Media Title', l.metadata['title']
    assert_equal 'Media Description', l.metadata['description']
    assert_equal 'Media Title', pm.media.metadata['title']
    assert_equal 'Media Description', pm.media.metadata['description']
    pm.analysis = { title: 'Project Media Title', content: 'Project Media Description' }
    pm.save!
    l = Media.find(l.id)
    pm = ProjectMedia.find(pm.id)
    assert_equal 'Media Title', l.metadata['title']
    assert_equal 'Media Description', l.metadata['description']
    assert_equal 'Project Media Title', pm.analysis['title']
    assert_equal 'Project Media Description', pm.analysis['content']
  end

  test "should cache and sort by demand" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    team = create_team
    p = create_project team: team
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    pm = create_project_media team: team, project_id: p.id, disable_es_callbacks: false
    ms_pm = get_es_id(pm)
    assert_queries(0, '=') { assert_equal(0, pm.demand) }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm
    assert_queries(0, '=') { assert_equal(1, pm.demand) }
    pm2 = create_project_media team: team, project_id: p.id, disable_es_callbacks: false
    ms_pm2 = get_es_id(pm2)
    assert_queries(0, '=') { assert_equal(0, pm2.demand) }
    2.times { create_dynamic_annotation(annotation_type: 'smooch', annotated: pm2) }
    assert_queries(0, '=') { assert_equal(2, pm2.demand) }
    # test sorting
    result = $repository.find(ms_pm)
    assert_equal result['demand'], 1
    result = $repository.find(ms_pm2)
    assert_equal result['demand'], 2
    result = CheckSearch.new({projects: [p.id], sort: 'demand'}.to_json, nil, team.id)
    assert_equal [pm2.id, pm.id], result.medias.map(&:id)
    result = CheckSearch.new({projects: [p.id], sort: 'demand', sort_type: 'asc'}.to_json, nil, team.id)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id)
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    assert_equal 1, pm.reload.requests_count
    assert_equal 2, pm2.reload.requests_count
    assert_queries(0, '=') { assert_equal(3, pm.demand) }
    assert_queries(0, '=') { assert_equal(3, pm2.demand) }
    pm3 = create_project_media team: team, project_id: p.id
    ms_pm3 = get_es_id(pm3)
    assert_queries(0, '=') { assert_equal(0, pm3.demand) }
    2.times { create_dynamic_annotation(annotation_type: 'smooch', annotated: pm3) }
    assert_queries(0, '=') { assert_equal(2, pm3.demand) }
    create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
    assert_queries(0, '=') { assert_equal(5, pm.demand) }
    assert_queries(0, '=') { assert_equal(5, pm2.demand) }
    assert_queries(0, '=') { assert_equal(5, pm3.demand) }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm3
    assert_queries(0, '=') { assert_equal(6, pm.demand) }
    assert_queries(0, '=') { assert_equal(6, pm2.demand) }
    assert_queries(0, '=') { assert_equal(6, pm3.demand) }
    r.destroy!
    assert_queries(0, '=') { assert_equal(4, pm.demand) }
    assert_queries(0, '=') { assert_equal(2, pm2.demand) }
    assert_queries(0, '=') { assert_equal(4, pm3.demand) }
    assert_queries(0, '>') { assert_equal(4, pm.demand(true)) }
    assert_queries(0, '>') { assert_equal(2, pm2.demand(true)) }
    assert_queries(0, '>') { assert_equal(4, pm3.demand(true)) }
  end

end