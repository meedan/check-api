require_relative '../test_helper'

class ElasticSearch7Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should index rules result" do
    t = create_team
    assert_nil t.rules_search_fields_json_schema
    p1 = create_project team: t
    p2 = create_project team: t
    rules = [
      {
        "name": "Test Rule 1",
        "project_ids": p1.id.to_s,
        "rules": [
          {
            "rule_definition": "contains_keyword",
            "rule_value": "hi,hello,sorry,please"
          }
        ],
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
        "rules": [
          {
            "rule_definition": "has_less_than_x_words",
            "rule_value": "3"
          }
        ],
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
    pm1 = create_project_media project: p1, quote: 'hello this is a test', disable_es_callbacks: false
    pm2 = create_project_media project: p1, quote: 'test', disable_es_callbacks: false
    pm3 = create_project_media project: p1, quote: 'please test', disable_es_callbacks: false
    
    sleep 10
    
    query = { bool: { must: { term: { rules: rule1 } } } }
    results = MediaSearch.search(query: query).results
    assert_equal [pm1.id, pm3.id].sort, results.map(&:annotated_id).sort
    results = CheckSearch.new({ rules: [rule1] }.to_json)
    assert_equal [pm1, pm3].sort, results.medias.sort
    
    query = { bool: { must: { term: { rules: rule2 } } } }
    results = MediaSearch.search(query: query).results
    assert_equal [pm2.id, pm3.id].sort, results.map(&:annotated_id).sort
    results = CheckSearch.new({ rules: [rule2] }.to_json)
    assert_equal [pm2, pm3].sort, results.medias.sort
    
    query = { bool: { must: [{ term: { rules: rule1 } }, { term: { rules: rule2 } }] } }
    results = MediaSearch.search(query: query).results
    assert_equal [pm3.id].sort, results.map(&:annotated_id).sort
    results = CheckSearch.new({ rules: [rule1, rule2] }.to_json)
    assert_equal [pm1, pm2, pm3].sort, results.medias.sort

    t = Team.find(t.id)
    rules = [
      {
        "name": "Test Rule 1",
        "project_ids": p2.id.to_s,
        "rules": [
          {
            "rule_definition": "contains_keyword",
            "rule_value": "foo,bar,test"
          },
          {
            "rule_definition": "has_less_than_x_words",
            "rule_value": "1"
          }
        ],
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
        "rules": [
          {
            "rule_definition": "contains_keyword",
            "rule_value": "hello,hi"
          },
          {
            "rule_definition": "has_less_than_x_words",
            "rule_value": "5"
          }
        ],
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
        "rules": [
          {
            "rule_definition": "contains_keyword",
            "rule_value": "please,thanks"
          },
          {
            "rule_definition": "has_less_than_x_words",
            "rule_value": "3"
          }
        ],
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
    results = MediaSearch.search(query: query).results
    assert_equal [pm2.id], results.map(&:annotated_id)
    results = CheckSearch.new({ rules: [rule1] }.to_json)
    assert_equal [pm2], results.medias
    
    query = { bool: { must: { term: { rules: rule2 } } } }
    results = MediaSearch.search(query: query).results
    assert_equal [pm1.id], results.map(&:annotated_id)
    results = CheckSearch.new({ rules: [rule2] }.to_json)
    assert_equal [pm1], results.medias

    query = { bool: { must: { term: { rules: rule3 } } } }
    results = MediaSearch.search(query: query).results
    assert_equal [pm3.id], results.map(&:annotated_id)
    results = CheckSearch.new({ rules: [rule3] }.to_json)
    assert_equal [pm3], results.medias
  end

  test "should notify if index is not updated" do
    t = create_team
    t.rules = [{ name: 'test' }].to_json
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
end
