require_relative '../test_helper'

class ElasticSearch7Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
    create_task_stuff
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
      # tests for group c
      result = CheckSearch.new({keyword: 'Sawy', keyword_fields: {team_tasks: [tt2.id]}}.to_json)
      assert_equal [pm2.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'Sawy', keyword_fields: {team_tasks: [tt2.id, tt3.id]}}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id).sort
      sleep 2
      query = 'query Search { search(query: "{\"keyword\":\"Sawy\",\"keyword_fields\":{\"fields\":[\"task_answers\",\"metadata_answers\"],\"team_tasks\":[' + tt2.id.to_s + ']}}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm2.id, pm3.id], ids.sort
    end
  end

  # Please add new tests to test/controllers/elastic_search_8_test.rb
end
