require_relative '../test_helper'

class ElasticSearch9Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should filter items by has_claim" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      pm4 = create_project_media team: t, disable_es_callbacks: false
      create_claim_description project_media: pm, disable_es_callbacks: false
      create_claim_description project_media: pm3, disable_es_callbacks: false
      sleep 2
      results = CheckSearch.new({ has_claim: ['ANY_VALUE'] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ has_claim: ['NO_VALUE'] }.to_json)
      assert_equal [pm2.id, pm4.id], results.medias.map(&:id).sort
    end
  end

  test "should filter feed by workspace" do
    RequestStore.store[:skip_cached_field_update] = false
    f = create_feed
    t1 = create_team ; f.teams << t1
    t2 = create_team ; f.teams << t2
    t3 = create_team ; f.teams << t3
    FeedTeam.update_all(shared: true)
    pm1 = create_project_media team: t1
    c1 = create_cluster project_media: pm1
    c1.project_medias << pm1
    pm2 = create_project_media team: t2
    c2 = create_cluster project_media: pm2
    c2.project_medias << pm2
    pm3 = create_project_media team: t3
    c2.project_medias << pm3
    sleep 2
    u = create_user
    create_team_user team: t1, user: u, role: 'admin'
    with_current_user_and_team(u, t1) do
      query = { clusterize: true, feed_id: f.id }
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id], result.medias.map(&:id).sort
      query[:cluster_teams] = [t1.id]
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id], result.medias.map(&:id)
      query[:cluster_teams] = [t2.id, t3.id]
      result = CheckSearch.new(query.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
      # Get current team
      assert_equal t1, result.team
    end
  end

  test "should filter feed by report status" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    f = create_feed
    f.teams << t
    FeedTeam.update_all(shared: true)
    pm1 = create_project_media team: t
    c1 = create_cluster project_media: pm1
    c1.project_medias << pm1
    pm2 = create_project_media team: t
    c2 = create_cluster project_media: pm2
    c2.project_medias << pm2
    sleep 2
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      publish_report(pm1)
      query = { clusterize: true, feed_id: f.id, report_status: ['published', 'unpublished'] }
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id], result.medias.map(&:id).sort
      query[:report_status] = ['published']
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id], result.medias.map(&:id)
      query[:report_status] = ['unpublished']
      result = CheckSearch.new(query.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
    end
  end

  test "should search for keywords with typos" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm1 = create_project_media team: t, quote: 'Foobar 1', disable_es_callbacks: false
      pm2 = create_project_media team: t, quote: 'Fobar 2', disable_es_callbacks: false
      pm3 = create_project_media team: t, quote: 'Test 3', disable_es_callbacks: false
      results = CheckSearch.new({ keyword: 'Foobar', fuzzy: true }.to_json)
      assert_equal [pm1.id, pm2.id].sort, results.medias.map(&:id).sort
      results = CheckSearch.new({ keyword: 'Fobar', fuzzy: true }.to_json)
      assert_equal [pm1.id, pm2.id].sort, results.medias.map(&:id).sort
      results = CheckSearch.new({ keyword: 'Test', fuzzy: true }.to_json)
      assert_equal [pm3.id], results.medias.map(&:id)
    end
  end

  test "should filter keyword by extracted text OCR" do
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    bot = create_alegre_bot(name: "alegre", login: "alegre")
    bot.approve!
    team = create_team
    bot.install_to!(team)
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Rails.stubs(:env).returns('development'.inquiry)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/text/similarity/search/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/image/classification/').with({ body: { uri: 'some/path' } }).to_return(body: {
        "result": valid_flags_data
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre/image/ocr/').with({ body: { url: 'some/path' } }).to_return(body: {
        "text": "ocr_text"
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre/image/similarity/').to_return(body: 'success')
      # Text extraction
      Bot::Alegre.unstub(:media_file_url)
      pm = create_project_media team: team, media: create_uploaded_image, disable_es_callbacks: false
      WebMock.stub_request(:post, 'http://alegre/image/similarity/search/').with(body: {context: {:has_custom_id=>true, :team_id=>pm.team_id}, match_across_content_types: true, threshold: 0.89, url: "some/path"}).to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre/image/similarity/search/').with(body: {context: {:has_custom_id=>true, :team_id=>pm.team_id}, match_across_content_types: true, threshold: 0.95, url: "some/path"}).to_return(body: {
        "result": []
      }.to_json)
      Bot::Alegre.stubs(:media_file_url).with(pm).returns("some/path")
      assert Bot::Alegre.run({ data: { dbid: pm.id }, event: 'create_project_media' })
      sleep 2
      Team.stubs(:current).returns(team)
      result = CheckSearch.new({keyword: 'ocr_text'}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'ocr_text', keyword_fields: {fields: ['extracted_text']}}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'ocr_text', keyword_fields: {fields: ['title']}}.to_json)
      assert_empty result.medias
      Team.unstub(:current)
      Bot::Alegre.unstub(:media_file_url)
    end
  end

  test "should search by non or any for choices tasks" do
    create_task_stuff
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_a' }.to_json }.to_json
      pm_tt.save!
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_b' }.to_json }.to_json
      pm2_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'ANY_VALUE' }]}.to_json)
      assert_equal [pm.id, pm2.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NO_VALUE' }]}.to_json)
      assert_equal [pm3.id], results.medias.map(&:id).sort
    end
  end

  test "should search by date range for tasks" do
    at = create_annotation_type annotation_type: 'task_response_datetime', label: 'Task Response Date Time'
    datetime = create_field_type field_type: 'datetime', label: 'Date Time'
    create_field_instance annotation_type_object: at, name: 'response_datetime', field_type_object: datetime
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'number'
    create_team_task team_id: t.id, type: 'datetime'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      start_time = Time.now - 4.months
      end_time = Time.now - 2.months
      pm2_tt.response = { annotation_type: 'task_response_datetime', set_fields: { response_datetime: start_time }.to_json }.to_json
      pm2_tt.save!
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt.response = { annotation_type: 'task_response_datetime', set_fields: { response_datetime: end_time }.to_json }.to_json
      pm3_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'DATE_RANGE', range: { start_time: start_time }}]}.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'DATE_RANGE', range: { start_time: start_time, end_time: end_time }}]}.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'DATE_RANGE', range: { start_time: start_time, end_time: end_time - 1.month }}]}.to_json)
      assert_equal [pm2.id], results.medias.map(&:id)
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'DATE_RANGE', range: { start_time: start_time + 1.month, max: end_time + 1.month }}]}.to_json)
      assert_equal [pm3.id], results.medias.map(&:id)
    end
  end

  test "should search by media id" do
    t = create_team
    u = create_user
    pm = create_project_media team: t, quote: 'claim a', disable_es_callbacks: false
    pm2 = create_project_media team: t, quote: 'claim b', disable_es_callbacks: false
    sleep 2
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      # Hit ES with option id
      # A) id is array (should ignore)
      query = 'query Search { search(query: "{\"id\":[' + pm.id.to_s + '],\"keyword\":\"claim\"}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm2.id], ids.sort
      # B) id is string and exists in ES
      query = 'query Search { search(query: "{\"id\":' + pm.id.to_s + ',\"keyword\":\"claim\"}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id], ids
      # C) id is string and not exists in ES
      $repository.delete(get_es_id(pm))
      query = 'query Search { search(query: "{\"id\":' + pm.id.to_s + ',\"keyword\":\"claim\"}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      assert_empty JSON.parse(@response.body)['data']['search']['medias']['edges']
    end
  end

  test "should sort by fact-check published on data" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    pm1 = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, disable_es_callbacks: false
    pm3 = create_project_media team: t, disable_es_callbacks: false
    sleep 2
    cd = create_claim_description project_media: pm3
    fc = create_fact_check claim_description: cd
    cd = create_claim_description project_media: pm1
    fc = create_fact_check claim_description: cd
    sleep 2
    result = CheckSearch.new({ sort: 'fact_check_published_on', sort_type: 'asc' }.to_json, nil, t.id)
    assert_equal [pm2.id, pm3.id, pm1.id], result.medias.map(&:id)
    result = CheckSearch.new({ sort: 'fact_check_published_on', sort_type: 'desc' }.to_json, nil, t.id)
    assert_equal [pm1.id, pm3.id, pm2.id], result.medias.map(&:id)
  end

  test "should filter feed by organization" do
    f = create_feed
    t1 = create_team ; f.teams << t1
    t2 = create_team ; f.teams << t2
    t3 = create_team ; f.teams << t3
    FeedTeam.update_all(shared: true)
    pm1 = create_project_media team: t1, disable_es_callbacks: false
    pm2 = create_project_media team: t2, disable_es_callbacks: false
    pm3 = create_project_media team: t3, disable_es_callbacks: false
    sleep 2
    u = create_user
    create_team_user team: t1, user: u, role: 'admin'
    with_current_user_and_team(u, t1) do
      query = { feed_id: f.id }
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id, pm3.id], result.medias.map(&:id).sort
      query[:feed_team_ids] = [t1.id, t3.id]
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm3.id], result.medias.map(&:id).sort
      query[:feed_team_ids] = [t2.id]
      result = CheckSearch.new(query.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
      query[:feed_team_ids] = []
      result = CheckSearch.new(query.to_json)
      assert_empty result.medias.map(&:id)
    end
  end

  # Please add new tests to test/controllers/elastic_search_10_test.rb
end
