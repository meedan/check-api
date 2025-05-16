require_relative '../test_helper'

class ElasticSearch10Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should cache and filter by published_by value" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t, user: u2, role: 'admin'
    pm = create_project_media team: t, disable_es_callbacks: false
    with_current_user_and_team(u, t) do
      assert_queries(0, '=') { assert_empty pm.published_by }
      r = publish_report(pm)
      pm = ProjectMedia.find(pm.id)
      data = {}
      data[u.id] = u.name
      assert_queries(0, '=') { assert_equal data, pm.published_by }
      u.name = 'update name'
      u.save!
      pm = ProjectMedia.find(pm.id)
      data[u.id] = 'update name'
      assert_queries(0, '=') { assert_equal data, pm.published_by }
      Rails.cache.clear
      assert_queries(0, '>') { assert_equal data, pm.published_by }
      pm2 = create_project_media team: t, disable_es_callbacks: false
      sleep 2
      result = $repository.find(get_es_id(pm))
      assert_equal u.id, result['published_by']
      result = $repository.find(get_es_id(pm2))
      assert_equal 0, result['published_by']
      # Filter by published by
      result = CheckSearch.new({ published_by: [u.id] }.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({ published_by: [u2.id] }.to_json)
      assert_empty result.medias.map(&:id)
      result = CheckSearch.new({ published_by: [u.id, u2.id] }.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      # pause report should reset published_by value
      r = Dynamic.find(r.id)
      r.set_fields = { state: 'paused' }.to_json
      r.action = 'pause'
      r.save!
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_empty pm.published_by }
    end
    # should log latest published_by user
    with_current_user_and_team(u2, t) do
      r = publish_report(pm)
      pm = ProjectMedia.find(pm.id)
      data = {}
      data[u2.id] = u2.name
      assert_queries(0, '=') { assert_equal data, pm.published_by }
    end
  end

  test "should filter by annotated_by value" do
    create_task_stuff
    t = create_team
    u = create_user
    u2 = create_user
    u3 = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t, user: u2, role: 'admin'
    create_team_user team: t, user: u3, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'free_text'
    tt2 = create_team_task team_id: t.id, type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    pm = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, disable_es_callbacks: false
    pm_tt = nil
    with_current_user_and_team(u, t) do
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'answer by u' }.to_json }.to_json
      pm_tt.save!
      sleep 2
      result = $repository.find(get_es_id(pm))
      assert_equal [u.id], result['annotated_by']
    end
    with_current_user_and_team(u2, t) do
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm_tt2.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_a' }.to_json }.to_json
      pm_tt2.save!
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'answer by u2' }.to_json }.to_json
      pm2_tt.save!
    end
    sleep 2
    # Filter by annotated by
    with_current_user_and_team(u, t) do
      result = CheckSearch.new({ annotated_by: [u.id] }.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({ annotated_by: [u2.id] }.to_json)
      assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
      result = CheckSearch.new({ annotated_by: [u3.id] }.to_json)
      assert_empty result.medias.map(&:id)
      result = CheckSearch.new({ annotated_by: [u.id, u2.id] }.to_json)
      assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
      result = CheckSearch.new({ annotated_by: [u.id, u2.id], annotated_by_operator: 'AND' }.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      # destroy response
      r = pm_tt.first_response_obj
      r.destroy
      sleep 2
      result = CheckSearch.new({ annotated_by: [u.id] }.to_json)
      assert_empty result.medias.map(&:id)
    end
  end

  test "should filter items by fact check language" do
    t = create_team
    t.set_languages(['en', 'fr'])
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, quote: 'claim a', disable_es_callbacks: false
      cd = create_claim_description project_media: pm, disable_es_callbacks: false
      create_fact_check claim_description: cd, language: 'en', disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      cd = create_claim_description project_media: pm2, disable_es_callbacks: false
      create_fact_check claim_description: cd, language: 'en', disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      cd = create_claim_description project_media: pm3, disable_es_callbacks: false
      create_fact_check claim_description: cd, language: 'fr', disable_es_callbacks: false
      pm4 = create_project_media team: t, disable_es_callbacks: false
      cd = create_claim_description project_media: pm4, disable_es_callbacks: false
      create_fact_check claim_description: cd, disable_es_callbacks: false
      sleep 2
      results = CheckSearch.new({ fc_language: ['en', 'fr'] }.to_json)
      assert_equal [pm.id, pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ fc_language: ['fr', 'und'] }.to_json)
      assert_equal [pm3.id, pm4.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ keyword: 'claim', fc_language: ['en', 'fr'] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
    end
  end

  test "should filter items by read-unread" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, quote: 'claim a', disable_es_callbacks: false
      # test read/unread
      pm.read = true
      pm.save!
      results = CheckSearch.new({ read: ['1'] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ read: ['0'] }.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ keyword: 'claim', read: ['0'] }.to_json)
      assert_equal [pm3.id], results.medias.map(&:id)
    end
  end

  test "should sort items by creator name" do
    t = create_team
    p = create_project team: t
    # create users with capital and small letters to verify sort with case insensitive
    u1 = create_user name: 'ahmad'
    u2 = create_user name: 'Ali'
    u3 = create_user name: 'Zahra'
    u4 = create_user name: 'Zein'
    create_team_user team: t, user: u1
    create_team_user team: t, user: u2
    create_team_user team: t, user: u3
    create_team_user team: t, user: u4
    RequestStore.store[:skip_cached_field_update] = false
    pm1 = create_project_media project: p, user: u1, disable_es_callbacks: false
    pm2 = create_project_media project: p, user: u2, disable_es_callbacks: false
    pm3 = create_project_media project: p, user: u3, disable_es_callbacks: false
    pm4 = create_project_media project: p, user: u4, disable_es_callbacks: false
    sleep 2
    result = CheckSearch.new({ projects: [p.id], sort: 'creator_name', sort_type: 'asc' }.to_json, nil, t.id)
    assert_equal [pm1.id, pm2.id, pm3.id, pm4.id], result.medias.map(&:id)
    result = CheckSearch.new({ projects: [p.id], sort: 'creator_name', sort_type: 'desc' }.to_json, nil, t.id)
    assert_equal [pm4.id, pm3.id, pm2.id, pm1.id], result.medias.map(&:id)
  end

  test "should index and search by language" do
    att = 'language'
    at = create_annotation_type annotation_type: att, label: 'Language'
    language = create_field_type field_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', field_type_object: language

    languages = ['pt', 'en', 'ar', 'es', 'pt-BR', 'pt-PT']
    ids = {}

    languages.each do |code|
      pm = create_project_media disable_es_callbacks: false
      d = create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: { language: code }.to_json, disable_es_callbacks: false
      ids[code] = pm.id
    end

    sleep languages.size * 2

    languages.each do |code|
      search = {
        query: {
          terms: {
            language: [code]
          }
        }
      }

      results = $repository.search(search).results
      assert_equal 1, results.size
      assert_equal ids[code], results.first['annotated_id']
    end
  end

  test "should filter by keyword and claim context fact-check url and source name fields" do
    t = create_team
    pm = create_project_media team: t, quote: 'search_title a'
    pm2 = create_project_media team: t, quote: 'search_title b'
    pm3 = create_project_media team: t, quote: 'search_title c'
    # add claim context to pm
    create_claim_description project_media: pm, context: 'claim_context a'
    # add fact-check url to pm2
    url = random_url
    cd = create_claim_description project_media: pm2, context: 'claim_context b'
    fc = create_fact_check claim_description: cd, url: url
    # add source to pm3
    s = create_source team: t, name: 'media_source'
    pm3.source_id = s.id
    pm3.disable_es_callbacks = false
    pm3.save!
    sleep 2
    result = CheckSearch.new({keyword: 'search_title'}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'claim_context', keyword_fields: {fields: ['claim_description_context']}}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: url, keyword_fields: {fields: ['fact_check_url']}}.to_json, nil, t.id)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'media_source', keyword_fields: {fields: ['source_name']}}.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
  end

  test "should filter by keyword and requests fields" do
    # Reuests fields are username, identifier and content
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'Data' => ['JSON', false] })
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    pm2 = create_project_media team: t
    whatsapp_uid = random_string
    whatsapp_data = {
      '_id' => random_string,
      'givenName' => 'Foo',
      'surname' => 'Bar',
      'signedUpAt' => '2019-01-30T03:47:33.740Z',
      'properties' => {},
      'conversationStarted' => true,
      'clients' => [{
        'id' => random_string,
        'active' => true,
        'lastSeen' => '2020-10-01T15:41:20.877Z',
        'platform' => 'whatsapp',
        'displayName' => '+55 12 3456-7890',
        'raw' => { 'from' => '551234567890', 'profile' => { 'name' => 'Foo Bar' } }
      }],
      'pendingClients' => []
    }
    create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: whatsapp_uid, smooch_user_data: { raw: whatsapp_data }.to_json }.to_json
    twitter_uid = random_string
    twitter_data = {
      'clients' => [{
        'id' => random_string,
        'active' => true,
        'lastSeen' => '2020-10-02T16:55:59.211Z',
        'platform' => 'twitter',
        'displayName' => 'Foo Bar',
        'info' => {
          'avatarUrl' => random_url
        },
        'raw' => {
          'location' => random_string,
          'screen_name' => 'foobar',
          'name' => 'Foo Bar',
          'id_str' => random_string,
          'id' => random_string
        }
      }]
    }
    create_dynamic_annotation annotated: pm2, annotation_type: 'smooch_user', set_fields: { smooch_user_id: twitter_uid, smooch_user_data: { raw: twitter_data }.to_json }.to_json
    with_current_user_and_team(u, t) do
      wa_smooch_data = { 'authorId' => whatsapp_uid, 'text' => 'smooch_request a', 'name' => 'wa_user', 'language' => 'en' }
      smooch_pm = create_tipline_request associated: pm, team_id: t.id, language: 'en', smooch_data: wa_smooch_data, disable_es_callbacks: false
      twitter_smooch_data = { 'authorId' => twitter_uid, 'text' => 'smooch_request b', 'name' => 'melsawy', 'language' => 'fr' }
      smooch_pm2 = create_tipline_request associated: pm2, team_id: t.id, language: 'fr', smooch_data: twitter_smooch_data, disable_es_callbacks: false
      sleep 2
      result = CheckSearch.new({keyword: 'smooch_request', keyword_fields: {fields: ['request_content']}}.to_json)
      assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
      result = CheckSearch.new({keyword: 'melsawy', keyword_fields: {fields: ['request_username']}}.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: '551234567890', keyword_fields: {fields: ['request_username']}}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      # filter by request language
      result = CheckSearch.new({request_language: ['en']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({request_language: ['fr']}.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
      result = CheckSearch.new({request_language: ['en', 'fr']}.to_json)
      assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
      result = CheckSearch.new({request_language: ['en', 'fr'], keyword: 'melsawy', keyword_fields: {fields: ['request_username']}}.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
      result = CheckSearch.new({request_language: ['ar']}.to_json)
      assert_empty result.medias.map(&:id)
      # Verify destroy smooch_data
      smooch_pm.destroy!
      sleep 2
      es_pm = $repository.find(get_es_id(pm))
      assert_empty es_pm['requests']
      # Verify create requests when force re-index
      pm2.create_elasticsearch_doc_bg({ force_creation: true })
      sleep 2
      es_pm2 = $repository.find(get_es_id(pm2))
      assert_equal 1, es_pm2['requests'].length
    end
  end

  test "should filter by link types" do
    t = create_team
    # Youtube
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "youtube", "title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_youtube = create_link url: url
    pm_youtube = create_project_media team: t, media: l_youtube, disable_es_callbacks: false
    # Twitter
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "twitter", "title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_twitter = create_link url: url
    pm_twitter = create_project_media team: t, media: l_twitter, disable_es_callbacks: false
    # Facebook
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "facebook", "title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_facebook = create_link url: url
    pm_facebook = create_project_media team: t, media: l_facebook, disable_es_callbacks: false
    # Instagram
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "instagram", "title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_instagram = create_link url: url
    pm_instagram = create_project_media team: t, media: l_instagram, disable_es_callbacks: false
    # tiktok
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "tiktok", "title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_tiktok = create_link url: url
    pm_tiktok = create_project_media team: t, media: l_tiktok, disable_es_callbacks: false
     # telegram
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "telegram", "title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_telegram = create_link url: url
    pm_telegram = create_project_media team: t, media: l_telegram, disable_es_callbacks: false
    # weblink
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "page", "title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_weblink = create_link url: url
    pm_weblink = create_project_media team: t, media: l_weblink, disable_es_callbacks: false
    sleep 2
    result = CheckSearch.new({show: ['youtube']}.to_json, nil, t.id)
    assert_equal [pm_youtube.id], result.medias.map(&:id)
    result = CheckSearch.new({show: ['twitter']}.to_json, nil, t.id)
    assert_equal [pm_twitter.id], result.medias.map(&:id)
    result = CheckSearch.new({show: ['facebook']}.to_json, nil, t.id)
    assert_equal [pm_facebook.id], result.medias.map(&:id)
    result = CheckSearch.new({show: ['instagram']}.to_json, nil, t.id)
    assert_equal [pm_instagram.id], result.medias.map(&:id)
    result = CheckSearch.new({show: ['tiktok']}.to_json, nil, t.id)
    assert_equal [pm_tiktok.id], result.medias.map(&:id)
    result = CheckSearch.new({show: ['telegram']}.to_json, nil, t.id)
    assert_equal [pm_telegram.id], result.medias.map(&:id)
    result = CheckSearch.new({show: ['weblink']}.to_json, nil, t.id)
    assert_equal [pm_weblink.id], result.medias.map(&:id)
    result = CheckSearch.new({show: ['youtube', 'twitter', 'facebook', 'instagram', 'tiktok', 'telegram', 'weblink']}.to_json, nil, t.id)
    assert_equal [pm_youtube.id, pm_twitter.id, pm_facebook.id, pm_instagram.id, pm_tiktok.id, pm_telegram.id, pm_weblink.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({show: ['links']}.to_json, nil, t.id)
    assert_equal [pm_youtube.id, pm_twitter.id, pm_facebook.id, pm_instagram.id, pm_tiktok.id, pm_telegram.id, pm_weblink.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({}.to_json, nil, t.id)
    assert_equal [pm_youtube.id, pm_twitter.id, pm_facebook.id, pm_instagram.id, pm_tiktok.id, pm_telegram.id, pm_weblink.id].sort, result.medias.map(&:id).sort
  end

  test "should filter by unmatched" do
    t = create_team
    source = create_project_media team: t, quote: 'source', disable_es_callbacks: false
    target = create_project_media team: t, quote: 'target', disable_es_callbacks: false
    target2 = create_project_media team: t, quote: 'target two', disable_es_callbacks: false
    r = create_relationship source_id: source.id, target_id: target.id, relationship_type: Relationship.confirmed_type
    r.destroy!
    r2 = create_relationship source_id: source.id, target_id: target2.id, relationship_type: Relationship.suggested_type
    r2.destroy!
    sleep 2
    Team.current = t
    result = CheckSearch.new({}.to_json)
    assert_equal 3, result.medias.count
    # filter by unmatched (hit PG)
    result = CheckSearch.new({ unmatched: [0, 1] }.to_json)
    assert_equal [source.id, target.id, target2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ unmatched: [0] }.to_json)
    assert_empty result.medias.map(&:id)
    result = CheckSearch.new({ unmatched: [1] }.to_json)
    assert_equal [source.id, target.id, target2.id].sort, result.medias.map(&:id).sort
    # filter by unmatched (hit ES)
    result = CheckSearch.new({ keyword: 'target', unmatched: [1] }.to_json)
    assert_equal [target.id, target2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ keyword: 'target', unmatched: [0] }.to_json)
    assert_empty result.medias.map(&:id)
    result = CheckSearch.new({ keyword: 'source', unmatched: [1] }.to_json)
    assert_equal [source.id], result.medias.map(&:id)
    result = CheckSearch.new({ keyword: 'source', unmatched: [0] }.to_json)
    assert_empty result.medias.map(&:id)
    Team.current = nil
  end

  test "should not apply feed filters until a list is chosen" do
    t1 = create_team
    create_project_media team: t1, disable_es_callbacks: false
    create_project_media team: t1, disable_es_callbacks: false
    ss1 = create_saved_search team: t1, filters: {}
    f = create_feed team: t1, media_saved_search: nil, data_points: [1, 2], published: true
    t2 = create_team
    create_project_media team: t2, disable_es_callbacks: false
    ss2 = create_saved_search team: t2, filters: {}
    ft = create_feed_team feed: f, team: t2, media_saved_search: nil, shared: true
    sleep 2
    Team.current = t1
    query = { feed_id: f.id, feed_view: 'media', show_similar: true }

    # No workspace has chosen a list yet
    assert_equal 0, CheckSearch.new(query.to_json, nil, t1.id).number_of_results

    # Only the first workspace has chosen a list
    f.media_saved_search = ss1
    f.save!
    assert_equal 2, CheckSearch.new(query.to_json, nil, t1.id).number_of_results

    # Only the second workspace has chosen a list
    f.media_saved_search = nil
    f.save!
    ft.media_saved_search = ss2
    ft.save!
    assert_equal 1, CheckSearch.new(query.to_json, nil, t1.id).number_of_results

    # Both workspaces have chosen a list
    f.media_saved_search = ss1
    f.save!
    ft.media_saved_search = ss2
    ft.save!
    assert_equal 3, CheckSearch.new(query.to_json, nil, t1.id).number_of_results

    Team.current = nil
  end

  test "should filter by positive_tipline_search_results_count and negative_tipline_search_results_count numeric range" do
    RequestStore.store[:skip_cached_field_update] = false
    p = create_project
    [:positive_tipline_search_results_count, :negative_tipline_search_results_count].each do |field|
      query = { projects: [p.id], "#{field}": { max: 5 } }
      query[field][:min] = 0
      result = CheckSearch.new(query.to_json, nil, p.team_id)
      assert_equal 0, result.medias.count
    end
    pm1 = create_project_media project: p, quote: 'Test A', disable_es_callbacks: false
    pm2 = create_project_media project: p, quote: 'Test B', disable_es_callbacks: false

    # Add positive search results
    create_tipline_request team_id: p.team_id, associated: pm1, smooch_request_type: 'relevant_search_result_requests'
    2.times { create_tipline_request(team_id: p.team_id, associated: pm2, smooch_request_type: 'relevant_search_result_requests') }

    # Add negative search results
    create_tipline_request team_id: p.team_id, associated: pm1, smooch_request_type: 'irrelevant_search_result_requests'
    2.times { create_tipline_request(team_id: p.team_id, associated: pm2, smooch_request_type: 'irrelevant_search_result_requests') }

    sleep 2

    min_mapping = {
      "0": [pm1.id, pm2.id],
      "1": [pm1.id, pm2.id],
      "2": [pm2.id],
      "3": [],
    }

    [:positive_tipline_search_results_count, :negative_tipline_search_results_count].each do |field|
      query = { projects: [p.id], "#{field}": { max: 5 } }
      min_mapping.each do |min, items|
        query[field][:min] = min.to_s
        result = CheckSearch.new(query.to_json, nil, p.team_id)
        assert_equal items.sort, result.medias.map(&:id).sort
      end
    end
  end
end
