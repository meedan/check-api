require_relative '../test_helper'

class ElasticSearch7Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
    create_task_stuff
  end

  test "should search for flag" do
    create_flag_annotation_type
    t = create_team
    p = create_project team: t

    pm1 = create_project_media project: p, disable_es_callbacks: false
    data = valid_flags_data(false)
    data[:flags]['spam'] = 3
    create_flag annotated: pm1, disable_es_callbacks: false, set_fields: data.to_json

    pm2 = create_project_media project: p, disable_es_callbacks: false
    data = valid_flags_data(false)
    data[:flags]['racy'] = 4
    create_flag annotated: pm2, disable_es_callbacks: false, set_fields: data.to_json

    sleep 5

    result = CheckSearch.new({ dynamic: { flag_name: ['spam'], flag_value: ['3'] } }.to_json, nil, t.id)
    assert_equal [pm1.id], result.medias.map(&:id)

    result = CheckSearch.new({ dynamic: { flag_name: ['racy'], flag_value: ['4'] } }.to_json, nil, t.id)
    assert_equal [pm2.id], result.medias.map(&:id)

    result = CheckSearch.new({ dynamic: { flag_name: ['racy', 'spam'], flag_value: ['3', '4'] } }.to_json, nil, t.id)
    assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

    result = CheckSearch.new({ dynamic: { flag_name: ['adult'], flag_value: ['5'] } }.to_json, nil, t.id)
    assert_equal [], result.medias
  end

  test "should search by task responses" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    tt2 = create_team_task team_id: t.id, type: 'multiple_choice', options: ['ans_a', 'ans_b', 'ans_c']
    tt3 = create_team_task team_id: t.id, type: 'free_text'
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
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_a' }.to_json }.to_json
      pm3_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'ans_a' }]}.to_json)
      assert_equal [pm, pm3], results.medias.sort
      results = CheckSearch.new({ team_tasks: [{ response: 'ans_b', id: tt.id }]}.to_json)
      assert_equal [pm2], results.medias
      results = CheckSearch.new({ team_tasks: [{ response: 'ans_c', id: tt.id }]}.to_json)
      assert_empty results.medias
      # Test with multiple choices
      pm4 = create_project_media team: t, disable_es_callbacks: false
      pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm4_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['ans_a', 'ans_c'], other: nil }.to_json }.to_json }.to_json
      pm4_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ response: 'ans_a', id: tt2.id }]}.to_json)
      assert_equal [pm4.id], results.medias.map(&:id)
      # Test with free text
      pm5 = create_project_media team: t, disable_es_callbacks: false
      pm6 = create_project_media team: t, disable_es_callbacks: false
      pm5_tt = pm5.annotations('task').select{|t| t.team_task_id == tt3.id}.last
      pm5_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Foo by Sawy' }.to_json }.to_json
      pm5_tt.save!
      pm6_tt = pm6.annotations('task').select{|t| t.team_task_id == tt3.id}.last
      pm6_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Bar by Sawy' }.to_json }.to_json
      pm6_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{response: 'Foo', response_type: 'free_text', id: tt3.id}]}.to_json)
      assert_equal [pm5.id], results.medias.map(&:id)
      results = CheckSearch.new({ team_tasks: [{response: 'Sawy', response_type: 'free_text', id: tt3.id}]}.to_json)
      assert_equal [pm5.id, pm6.id], results.medias.map(&:id).sort
      # Search with different cases
      # A) Test with choice (single/multiple) (exact match)
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":\"ans_a\",\"response_type\":\"choice\",\"id\":' +  tt.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm3.id], ids.sort
      # B) Test with free text (partial match)
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":\"sawy\",\"response_type\":\"free_text\",\"id\":' +  tt3.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm5.id, pm6.id], ids.sort
      # Search in multiple team tasks
      results = CheckSearch.new({team_tasks: [{id: tt.id, response: 'ans_a'}, {id: tt2.id, response: 'ans_a'}]}.to_json)
      assert_empty results.medias
      # "AND" for muliple filters
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['ans_a', 'ans_c'], other: nil }.to_json }.to_json }.to_json
      pm_tt.save!
      sleep 2
      results = CheckSearch.new({team_tasks: [{id: tt.id, response: 'ans_a'}, {id: tt2.id, response: 'ans_c'}]}.to_json)
      assert_equal [pm], results.medias
      # C) "OR" for multiple responses
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":[\"ans_a\",\"ans_b\",\"ans_c\"],\"response_type\":\"choice\",\"id\":' +  tt.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm2.id, pm3.id], ids.sort
    end
  end

  test "should update and destroy responses in es" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    tt2 = create_team_task team_id: t.id, type: 'multiple_choice', options: ['choice_a', 'choice_b', 'choice_c']
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      es_id = get_es_id(pm)
      # answer single choice
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_a' }.to_json }.to_json
      pm_tt.save!
      # answer multiple choice
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm_tt2.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['choice_a', 'choice_b'], other: nil }.to_json }.to_json }.to_json
      pm_tt2.save!
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      assert_equal ['ans_a'], sc['value']
      assert_equal ['choice_a', 'choice_b'], mc['value']
      # update answers for single and multiple
      pm_tt = Task.find(pm_tt.id)
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_b' }.to_json }.to_json
      pm_tt.save!
      pm_tt2 = Task.find(pm_tt2.id)
      pm_tt2.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['choice_c'], other: nil }.to_json }.to_json }.to_json
      pm_tt2.save!
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      assert_equal ['ans_b'], sc['value']
      assert_equal ['choice_c'], mc['value']
      # destroy responses
      pm_tt = Task.find(pm_tt.id)
      sc_response = pm_tt.first_response_obj
      sc_response.destroy
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      # destroy should remove answer value
      assert_nil sc['value']
      assert_equal ['choice_c'], mc['value']
      # destroy mmultiple choice answer
      pm_tt2 = Task.find(pm_tt2.id)
      mc_response = pm_tt2.first_response_obj
      mc_response.destroy
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      assert_nil sc['value']
      assert_nil mc['value']
    end
  end

  test "should parse search options" do
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    pm2 = create_project_media project: p2, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # pass wrong format should map to all items
    result = CheckSearch.new({projects: [p.id]})
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
  end

  test "should filter keyword by fields group a" do
    create_verification_status_stuff(false)
    t = create_team
    p = create_project team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    url2 = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url2 + '/normalized","type":"item", "title": "search_title", "description":"another_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    m1 = create_media(account: create_valid_account, url: url2)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm2 = create_project_media project: p, media: m1, disable_es_callbacks: false
    # add analysis to pm2
    pm2.analysis = { title: 'override_title', content: 'override_description' }
    # add tags to pm3
    pm3 = create_project_media project: p, disable_es_callbacks: false
    create_tag tag: 'search_title', annotated: pm3, disable_es_callbacks: false
    create_tag tag: 'another_desc', annotated: pm3, disable_es_callbacks: false
    create_tag tag: 'newtag', annotated: pm3, disable_es_callbacks: false
    sleep 2
    result = CheckSearch.new({keyword: 'search_title'}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['title']}}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'search_desc', keyword_fields: {fields: ['description']}}.to_json, nil, t.id)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'override_title', keyword_fields: {fields: ['analysis_title']}}.to_json, nil, t.id)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['analysis_title']}}.to_json, nil, t.id)
    assert_empty result.medias
    result = CheckSearch.new({keyword: 'override_description', keyword_fields: {fields: ['analysis_description']}}.to_json, nil, t.id)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['tags']}}.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'another_desc', keyword_fields: {fields:['description', 'tags']}}.to_json, nil, t.id)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id).sort
  end

  test "should filter keyword by fields group b" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'single_choice', options: ['Foo', 'Bar', 'ans_c']
    tt2 = create_team_task team_id: t.id, type: 'free_text'
    tt3 = create_team_task team_id: t.id, type: 'free_text', fieldset: 'metadata'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'Foo' }.to_json }.to_json
      pm_tt.save!
      # test with free text
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm2_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Foo by Sawy' }.to_json }.to_json
      pm2_tt.save!
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt3.id}.last
      pm3_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Bar by Sawy' }.to_json }.to_json
      pm3_tt.save!
      # add task/item notes
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      create_comment annotated: pm, text: 'item notepm', disable_es_callbacks: false
      create_comment annotated: pm2, text: 'item comment', disable_es_callbacks: false
      create_comment annotated: pm_tt2, text: 'task notepm', disable_es_callbacks: false
      create_comment annotated: pm2_tt, text: 'task comment', disable_es_callbacks: false
      create_comment annotated: pm3_tt, text: 'task notepm', disable_es_callbacks: false
      sleep 2
      result = CheckSearch.new({keyword: 'Sawy'}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id).sort
      result = CheckSearch.new({keyword: 'Foo', keyword_fields: {fields:['task_answers']}}.to_json)
      assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
      result = CheckSearch.new({keyword: 'Sawy', keyword_fields: {fields: ['metadata_answers']}}.to_json)
      assert_equal [pm3.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'Sawy', keyword_fields: {fields: ['task_answers', 'metadata_answers']}}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id).sort
      result = CheckSearch.new({keyword: 'item', keyword_fields: {fields: ['comments']}}.to_json)
      assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
      result = CheckSearch.new({keyword: 'item', keyword_fields: {fields: ['task_comments']}}.to_json)
      assert_empty result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'task', keyword_fields: {fields: ['task_comments']}}.to_json)
      assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
      result = CheckSearch.new({keyword: 'notepm', keyword_fields: {fields: ['comments', 'task_comments']}}.to_json)
      assert_equal [pm.id, pm3.id], result.medias.map(&:id).sort
      # tests for group c
      result = CheckSearch.new({keyword: 'Sawy', keyword_fields: {team_tasks: [tt2.id]}}.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'Sawy', keyword_fields: {team_tasks: [tt2.id, tt3.id]}}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id).sort
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      create_comment annotated: pm_tt2, text: 'comment by Sawy', disable_es_callbacks: false
      sleep 2
      result = CheckSearch.new({keyword: 'Sawy', keyword_fields: {team_tasks: [tt2.id]}}.to_json)
      assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
      query = 'query Search { search(query: "{\"keyword\":\"Sawy\",\"keyword_fields\":{\"fields\":[\"task_answers\",\"metadata_answers\"],\"team_tasks\":[' + tt2.id.to_s + ']}}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm2.id, pm3.id], ids.sort
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
    Bot::Alegre.unstub(:request_api)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:get, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:get, 'http://alegre/image/similarity/').to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre/image/classification/').with({ query: { uri: 'some/path' } }).to_return(body: {
        "result": valid_flags_data
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre/image/ocr/').with({ query: { url: 'some/path' } }).to_return(body: {
        "text": "ocr_text"
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre/image/similarity/').to_return(body: 'success')
      # Text extraction
      Bot::Alegre.unstub(:media_file_url)
      pm = create_project_media team: team, media: create_uploaded_image, disable_es_callbacks: false
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

  test "should search by source" do
    t = create_team
    s = create_source team: t
    s2 = create_source team: t
    s3 = create_source team: t
    pm = create_project_media team: t, source: s, disable_es_callbacks: false, skip_autocreate_source: false
    pm2 = create_project_media team: t, source: s, disable_es_callbacks: false, skip_autocreate_source: false
    pm3 = create_project_media team: t, source: s2, disable_es_callbacks: false, skip_autocreate_source: false
    sleep 2
    result = CheckSearch.new({ sources: [s.id] }.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s2.id] }.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({ sources: [s.id, s2.id] }.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s3.id] }.to_json, nil, t.id)
    assert_empty result.medias
    result = CheckSearch.new({ sources: [s2.id], show: ['links'] }.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
  end

  test "should search trash and unconfirmed items" do
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm3 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm4 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED, disable_es_callbacks: false
    sleep 2
    assert_equal [pm2, pm3], pm.check_search_trash.medias.sort
    assert_equal [pm, pm4], t.check_search_team.medias.sort
  end

  test "should adjust ES window size" do
    t = create_team
    u = create_user
    pm = create_project_media quote: 'claim a', disable_es_callbacks: false
    sleep 2
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      assert_nothing_raised do
        query = 'query Search { search(query: "{\"keyword\":\"claim\",\"eslimit\":20000,\"esoffset\":0}") {medias(first:20){edges{node{dbid}}}}}'
        post :create, params: { query: query }
        assert_response :success
        query = 'query Search { search(query: "{\"keyword\":\"claim\",\"eslimit\":10000,\"esoffset\":20}") {medias(first:20){edges{node{dbid}}}}}'
        post :create, params: { query: query }
        assert_response :success
      end
    end
  end

  test "should search by media url" do
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","title": "media_title"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, url: url, disable_es_callbacks: false
      sleep 2
      result = $repository.find(get_es_id(pm))['url']
      assert_equal result, url
      results = CheckSearch.new({ keyword: 'test.com' }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ keyword: 'test2.com' }.to_json)
      assert_empty results.medias.map(&:id)
      results = CheckSearch.new({keyword: 'test.com', keyword_fields: {fields: ['url']}}.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({keyword: 'test.com', keyword_fields: {fields: ['title']}}.to_json)
      assert_empty results.medias.map(&:id)
    end
  end

  test "should filter items by channel" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, quote: 'claim a', channel: { main: CheckChannels::ChannelCodes::MANUAL }, disable_es_callbacks: false
      pm2 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::FETCH }, disable_es_callbacks: false
      pm3 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::API }, disable_es_callbacks: false
      pm4 = create_project_media team: t, quote: 'claim b', channel: { main: CheckChannels::ChannelCodes::ZAPIER }, disable_es_callbacks: false
      # tipline items
      pm5 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::WHATSAPP }, disable_es_callbacks: false
      pm6 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::MESSENGER }, disable_es_callbacks: false
      pm7 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::TWITTER }, disable_es_callbacks: false
      pm8 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::TELEGRAM }, disable_es_callbacks: false
      pm9 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::VIBER }, disable_es_callbacks: false
      pm10 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::LINE }, disable_es_callbacks: false
      tipline_ids = [pm5.id, pm6.id, pm7.id, pm8.id, pm9.id, pm10.id]
      sleep 2
      # Hit PG
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MANUAL] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::API] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
      # Hit ES
      results = CheckSearch.new({ keyword: 'claim', channels: [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::API] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      # filter by any tipline
      results = CheckSearch.new({ channels: ['any_tipline'] }.to_json)
      assert_equal tipline_ids, results.medias.map(&:id).sort
      results = CheckSearch.new({ channels: ['any_tipline', CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::TWITTER] }.to_json)
      assert_equal tipline_ids.concat([pm.id]).sort, results.medias.map(&:id).sort
    end
  end

  test "should filter items by channel in main and others" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, quote: 'claim a', channel: { main: CheckChannels::ChannelCodes::MANUAL }, disable_es_callbacks: false
      pm2 = create_project_media team: t, quote: 'claim b', channel: { main: CheckChannels::ChannelCodes::ZAPIER }, disable_es_callbacks: false
      # tipline items
      pm3 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::WHATSAPP }, disable_es_callbacks: false
      pm.channel = { main: CheckChannels::ChannelCodes::MANUAL, others: [CheckChannels::ChannelCodes::WHATSAPP, CheckChannels::ChannelCodes::MESSENGER] }
      pm.save!
      sleep 2
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MANUAL] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::WHATSAPP] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::WHATSAPP, CheckChannels::ChannelCodes::ZAPIER] }.to_json)
      assert_equal [pm.id, pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MESSENGER] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      # filter by any tipline
      results = CheckSearch.new({ channels: ['any_tipline'] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
    end
  end
  
  # Please add new tests to test/controllers/elastic_search_8_test.rb
end
