require_relative '../test_helper'

class ElasticSearch7Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
    create_task_stuff
  end

  test "should index rules result" do
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    t = create_team
    assert_nil t.rules_search_fields_json_schema
    p1 = create_project team: t
    p2 = create_project team: t
    rules = [
      {
        "name": "Test Rule 1",
        "project_ids": p1.id.to_s,
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "contains_keyword",
                  "rule_value": "hi,hello,sorry,please"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p2.id.to_s
          }
        ]
      },
      {
        "name": "Test Rule 2",
        "project_ids": p1.id.to_s,
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "has_less_than_x_words",
                  "rule_value": "3"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p2.id.to_s
          }
        ]
      }
    ]
    t.rules = rules.to_json
    t.save!
    t = Team.find(t.id)
    assert_equal 2, t.rules_search_fields_json_schema[:properties][:rules][:properties].keys.size
    rule1 = Team.rule_id(rules[0])
    rule2 = Team.rule_id(rules[1])
    pm1 = create_project_media project: p1, quote: 'hello this is a test', disable_es_callbacks: false, smooch_message: { 'text' => 'hello this is a test' }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm1, set_fields: { smooch_data: { 'text' => 'hello this is a test' }.to_json }.to_json
    pm2 = create_project_media project: p1, quote: 'test', disable_es_callbacks: false, smooch_message: { 'text' => 'test' }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm2, set_fields: { smooch_data: { 'text' => 'test' }.to_json }.to_json
    pm3 = create_project_media project: p1, quote: 'please test', disable_es_callbacks: false, smooch_message: { 'text' => 'please test' }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm3, set_fields: { smooch_data: { 'text' => 'please test' }.to_json }.to_json
    
    sleep 10
    
    query = { bool: { must: { term: { rules: rule1 } } } }
    results = $repository.search(query: query).results
    assert_equal [pm1.id, pm3.id].sort, results.collect{|i| i['annotated_id']}.sort
    results = CheckSearch.new({ rules: [rule1] }.to_json)
    assert_equal [pm1, pm3].sort, results.medias.sort
    
    query = { bool: { must: { term: { rules: rule2 } } } }
    results = $repository.search(query: query).results
    assert_equal [pm2.id, pm3.id].sort, results.collect{|i| i['annotated_id']}.sort
    results = CheckSearch.new({ rules: [rule2] }.to_json)
    assert_equal [pm2, pm3].sort, results.medias.sort
    
    query = { bool: { must: [{ term: { rules: rule1 } }, { term: { rules: rule2 } }] } }
    results = $repository.search(query: query).results
    assert_equal [pm3.id].sort, results.collect{|i| i['annotated_id']}.sort
    results = CheckSearch.new({ rules: [rule1, rule2] }.to_json)
    assert_equal [pm1, pm2, pm3].sort, results.medias.sort

    t = Team.find(t.id)
    rules = [
      {
        "name": "Test Rule 1",
        "project_ids": p2.id.to_s,
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "contains_keyword",
                  "rule_value": "foo,bar,test"
                },
                {
                  "rule_definition": "has_less_than_x_words",
                  "rule_value": "1"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p1.id.to_s
          }
        ]
      },
      {
        "name": "Test Rule 2",
        "project_ids": p2.id.to_s,
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "contains_keyword",
                  "rule_value": "hello,hi"
                },
                {
                  "rule_definition": "has_less_than_x_words",
                  "rule_value": "5"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p1.id.to_s
          }
        ]
      },
      {
        "name": "Test Rule 3",
        "project_ids": p2.id.to_s,
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "contains_keyword",
                  "rule_value": "please,thanks"
                },
                {
                  "rule_definition": "has_less_than_x_words",
                  "rule_value": "3"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p1.id.to_s
          }
        ]
      }
    ]
    t.rules = rules.to_json
    t.save!
    rule3 = Team.rule_id(rules[2])

    sleep 10

    query = { bool: { must: { term: { rules: rule1 } } } }
    results = $repository.search(query: query).results
    assert_equal [pm2.id], results.collect{|i| i['annotated_id']}
    results = CheckSearch.new({ rules: [rule1] }.to_json)
    assert_equal [pm2], results.medias
    
    query = { bool: { must: { term: { rules: rule2 } } } }
    results = $repository.search(query: query).results
    assert_equal [pm1.id], results.collect{|i| i['annotated_id']}
    results = CheckSearch.new({ rules: [rule2] }.to_json)
    assert_equal [pm1], results.medias

    query = { bool: { must: { term: { rules: rule3 } } } }
    results = $repository.search(query: query).results
    assert_equal [pm3.id], results.collect{|i| i['annotated_id']}
    results = CheckSearch.new({ rules: [rule3] }.to_json)
    assert_equal [pm3], results.medias
  end

  test "should notify if index is not updated" do
    t = create_team
    t.rules = [
      {
        name: 'test',
        rules: {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": []
            }
          ]
        }
      }
    ].to_json
    t.save!
    CheckElasticSearchModel.stubs(:get_index_alias).raises(StandardError)
    Team.expects(:notify_error).once
    RulesIndexWorker.new.perform(t.id)
    Team.unstub(:notify_error)
    CheckElasticSearchModel.unstub(:get_index_alias)
  end

  test "should cancel index operation" do
    assert RulesIndexWorker.new.cancel(create_team.id)
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

    result = CheckSearch.new({ dynamic: { flag_name: ['spam'], flag_value: ['3'] } }.to_json)
    assert_equal [pm1.id], result.medias.map(&:id)

    result = CheckSearch.new({ dynamic: { flag_name: ['racy'], flag_value: ['4'] } }.to_json)
    assert_equal [pm2.id], result.medias.map(&:id)

    result = CheckSearch.new({ dynamic: { flag_name: ['racy', 'spam'], flag_value: ['3', '4'] } }.to_json)
    assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

    result = CheckSearch.new({ dynamic: { flag_name: ['adult'], flag_value: ['5'] } }.to_json)
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
      # test with multiple choices
      pm4 = create_project_media team: t, disable_es_callbacks: false
      pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm4_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['ans_a', 'ans_c'], other: nil }.to_json }.to_json }.to_json
      pm4_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ response: 'ans_a', id: tt2.id }]}.to_json)
      assert_equal [pm4.id], results.medias.map(&:id)
      # test with free text
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
      # search with different cases
      # A) test with choice (single/multiple) [exact match]
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":\"ans_a\",\"response_type\":\"choice\",\"id\":' +  tt.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, query: query
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm3.id], ids.sort
      # B) test with free text (contain match)
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":\"sawy\",\"response_type\":\"free_text\",\"id\":' +  tt3.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, query: query
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm5.id, pm6.id], ids.sort
      # Search in multiple team tasks
      results = CheckSearch.new({team_tasks: [{id: tt.id, response: 'ans_a'}, {id: tt2.id, response: 'ans_a'}]}.to_json)
      assert_empty results.medias
      # should AND for muliple filters
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['ans_a', 'ans_c'], other: nil }.to_json }.to_json }.to_json
      pm_tt.save!
      sleep 2
      results = CheckSearch.new({team_tasks: [{id: tt.id, response: 'ans_a'}, {id: tt2.id, response: 'ans_c'}]}.to_json)
      assert_equal [pm], results.medias
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
    result = CheckSearch.new({keyword: 'search_title'}.to_json)
    assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['title']}}.to_json)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'search_desc', keyword_fields: {fields: ['description']}}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'override_title', keyword_fields: {fields: ['analysis_title']}}.to_json)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['analysis_title']}}.to_json)
    assert_empty result.medias
    result = CheckSearch.new({keyword: 'override_description', keyword_fields: {fields: ['analysis_description']}}.to_json)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['tags']}}.to_json)
    assert_equal [pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'another_desc', keyword_fields: {fields:['description', 'tags']}}.to_json)
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
      post :create, query: query
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm2.id, pm3.id], ids.sort
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
      post :create, query: query
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm2.id], ids.sort
      # B) id is string and exists in ES
      query = 'query Search { search(query: "{\"id\":' + pm.id.to_s + ',\"keyword\":\"claim\"}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, query: query
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id], ids
      # C) id is string and not exists in ES
      $repository.delete(get_es_id(pm))
      query = 'query Search { search(query: "{\"id\":' + pm.id.to_s + ',\"keyword\":\"claim\"}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, query: query
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
    sleep 5
    result = CheckSearch.new({ sources: [s.id] }.to_json)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s2.id] }.to_json)
    assert_equal [pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({ sources: [s.id, s2.id] }.to_json)
    assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s3.id] }.to_json)
    assert_empty result.medias
  end

  test "should search trash and unconfirmed items" do
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm3 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm4 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED, disable_es_callbacks: false
    sleep 2
    assert_equal [pm2, pm3], pm.check_search_trash.medias.sort
    assert_equal [pm4], pm.check_search_unconfirmed.medias
    assert_equal [pm], t.check_search_team.medias
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
        post :create, query: query
        assert_response :success
        query = 'query Search { search(query: "{\"keyword\":\"claim\",\"eslimit\":10000,\"esoffset\":20}") {medias(first:20){edges{node{dbid}}}}}'
        post :create, query: query
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
end
