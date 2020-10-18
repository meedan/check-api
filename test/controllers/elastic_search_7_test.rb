require_relative '../test_helper'

class ElasticSearch7Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
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
                  "rule_value": "4"
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
                  "rule_value": "2"
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
                  "rule_value": "6"
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
                  "rule_value": "4"
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
    create_task_stuff
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
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
      assert_equal [pm, pm3, pm4], results.medias.sort
    end
  end

  test "should update and destroy responses in es" do
    create_task_stuff
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
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
      assert_nil sc
      assert_equal ['choice_c'], mc['value']
      # destroy mmultiple choice answer
      pm_tt2 = Task.find(pm_tt2.id)
      mc_response = pm_tt2.first_response_obj
      mc_response.destroy
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      assert_nil sc
      assert_nil mc
    end
  end
end
