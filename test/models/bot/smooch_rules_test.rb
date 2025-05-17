require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::SmoochRulesTest < ActiveSupport::TestCase
  def setup
    super
    TiplineResource.destroy_all
    setup_smooch_bot
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should route to project based on rules" do
    RequestStore.store[:skip_delete_for_ever] = true
    s1 = @team.settings.clone
    s2 = @team.settings.clone
    s2['rules'] = [
      {
        "name": "Rule 3",
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "request_matches_regexp",
                  "rule_value": "[0-9]+"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "send_to_trash",
            "action_value": ""
          }
        ]
      },
      {
        "name": "Rule 4",
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "request_matches_regexp",
                  "rule_value": "bad word"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "send_to_trash",
            "action_value": ""
          },
          {
            "action_definition": "ban_submitter",
            "action_value": ""
          }
        ]
      }
    ]
    @team.settings = s2
    @team.save!
    uid = random_string

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        source: { type: "whatsapp" },
        language: 'en',
        text: ([random_string] * 10).join(' ')
      }
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    assert Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    assert_equal @team.default_folder.id, pm.project_id
    assert_equal @team.id, pm.team_id
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived

    quote = 'The lazy dog jumped over the brown fox'
    pm = create_project_media team: @team, quote: quote, media: nil
    pm.archived = CheckArchivedFlags::FlagCodes::UNCONFIRMED
    pm.save!
    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        source: { type: "whatsapp" },
        language: 'en',
        text: quote
      }
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    assert Bot::Smooch.run(payload)
    pm = ProjectMedia.find(pm.id)
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        source: { type: "whatsapp" },
        language: 'en',
        text: random_number.to_s + ' ' + random_string
      }
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    assert Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.archived

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        source: { type: "whatsapp" },
        language: 'en',
        text: [random_string, random_string, random_string, 'bad word', random_string, random_string].join(' ')
      }
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    assert_nil Rails.cache.read("smooch:banned:#{uid}")
    assert Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.archived
    assert_not_nil Rails.cache.read("smooch:banned:#{uid}")

    @team.settings = s1
    @team.save!
  end

  test "should match keyword with rule" do
    ['^&$#(hospital', 'hospital?!', 'Hospital!!!'].each do |text|
      pm = create_project_media quote: text, team: @team, smooch_message: { 'text' => text }
      assert @team.contains_keyword(pm, 'hospital', nil)
    end
  end

  # TODO: Review by Sawy (change rule action)
  # test "should match rule by number of words and type" do
  #   p0 = create_project team: @team
  #   p1 = create_project team: @team
  #   rules = []
  #   rules << {
  #     "name": random_string,
  #     "project_ids": "",
  #     "rules": {
  #       "operator": "and",
  #       "groups": [
  #         {
  #           "operator": "and",
  #           "conditions": [
  #             {
  #               "rule_definition": "has_less_than_x_words",
  #               "rule_value": "3"
  #             },
  #             {
  #               "rule_definition": "type_is",
  #               "rule_value": "claim"
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #     "actions": [
  #       {
  #         "action_definition": "move_to_project",
  #         "action_value": p1.id.to_s
  #       }
  #     ]
  #   }
  #   @team.rules = rules.to_json
  #   @team.save!
  #   assert_equal 0, Project.find(p0.id).project_medias.count
  #   assert_equal 0, Project.find(p1.id).project_medias.count
  #   m = create_claim_media quote: 'test'
  #   create_project_media project: p0, media: m, smooch_message: { 'text' => 'test' }
  #   m = create_link team: @team
  #   create_project_media project: p0, media: m, smooch_message: { 'text' => 'test' }
  #   assert_equal 1, Project.find(p0.id).project_medias.count
  #   assert_equal 1, Project.find(p1.id).project_medias.count
  # end

  # TODO: Review by Sawy (change rule action)
  # test "should match rule by number of words" do
  #   p0 = create_project team: @team
  #   p1 = create_project team: @team
  #   rules = []
  #   rules << {
  #     "name": random_string,
  #     "project_ids": "",
  #     "rules": {
  #       "operator": "and",
  #       "groups": [
  #         {
  #           "operator": "and",
  #           "conditions": [
  #             {
  #               "rule_definition": "has_less_than_x_words",
  #               "rule_value": "3"
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #     "actions": [
  #       {
  #         "action_definition": "move_to_project",
  #         "action_value": p1.id.to_s
  #       }
  #     ]
  #   }
  #   @team.rules = rules.to_json
  #   @team.save!
  #   assert_equal 0, Project.find(p0.id).project_medias.count
  #   assert_equal 0, Project.find(p1.id).project_medias.count
  #   create_project_media project: p0, media: create_claim_media, smooch_message: { 'text' => 'test' }
  #   assert_equal 0, Project.find(p0.id).project_medias.count
  #   assert_equal 1, Project.find(p1.id).project_medias.count
  # end

  # TODO: Review by Sawy (change rule action)
  # test "should match with regexp" do
  #   p0 = create_project team: @team
  #   p1 = create_project team: @team
  #   p2 = create_project team: @team
  #   rules = []
  #   rules << {
  #     "name": random_string,
  #     "project_ids": "",
  #     "rules": {
  #       "operator": "and",
  #       "groups": [
  #         {
  #           "operator": "and",
  #           "conditions": [
  #             {
  #               "rule_definition": "title_matches_regexp",
  #               "rule_value": "^start_with_title"
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #     "actions": [
  #       {
  #         "action_definition": "move_to_project",
  #         "action_value": p1.id.to_s
  #       }
  #     ]
  #   }
  #   rules << {
  #     "name": random_string,
  #     "project_ids": "",
  #     "rules": {
  #       "operator": "and",
  #       "groups": [
  #         {
  #           "operator": "and",
  #           "conditions": [
  #             {
  #               "rule_definition": "request_matches_regexp",
  #               "rule_value": "^start_with_request"
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #     "actions": [
  #       {
  #         "action_definition": "move_to_project",
  #         "action_value": p2.id.to_s
  #       }
  #     ]
  #   }
  #   @team.rules = rules.to_json
  #   @team.save!
  #   pm1 = create_project_media project: p0, quote: 'start_with_title match title'
  #   assert_equal p1.id, pm1.reload.project_id
  #   pm2 = create_project_media project: p0, quote: 'title', smooch_message: { 'text' => 'start_with_request match request' }
  #   assert_equal p2.id, pm2.reload.project_id
  #   pm3 = create_project_media project: p0, quote: 'did not match', smooch_message: { 'text' => 'did not match' }
  #   assert_equal p0.id, pm3.reload.project_id
  # end

  test "should skip permission when applying action" do
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
                "rule_definition": "has_less_than_x_words",
                "rule_value": "3"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "send_to_trash",
        }
      ]
    }
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
                "rule_definition": "has_less_than_x_words",
                "rule_value": "4"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "send_to_trash",
        }
      ]
    }
    @team.rules = rules.to_json
    @team.save!
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","title":"this is a test","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_nothing_raised do
      with_current_user_and_team(@bot, @team) do
        create_project_media team: @team, media: nil, url: url, smooch_message: { 'text' => 'test' }
      end
    end
  end

  # TODO: Review by Sawy (change rule action)
  # test "should support emojis in regexp rule" do
  #   p0 = create_project team: @team
  #   p1 = create_project team: @team
  #   rules = [{
  #     "name": random_string,
  #     "project_ids": "",
  #     "rules": {
  #       "operator": "and",
  #       "groups": [
  #         {
  #           "operator": "and",
  #           "conditions": [
  #             {
  #               "rule_definition": "title_matches_regexp",
  #               "rule_value": "/(\\u00a9|\\u00ae|[\\u2000-\\u3300]|\\ud83c[\\ud000-\\udfff]|\\ud83d[\\ud000-\\udfff]|\\ud83e[\\ud000-\\udfff])/gmi"
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #     "actions": [
  #       {
  #         "action_definition": "move_to_project",
  #         "action_value": p1.id.to_s
  #       }
  #     ]
  #   }]
  #   @team.rules = rules.to_json
  #   assert_raises ActiveRecord::RecordInvalid do
  #     @team.save!
  #   end
  #   rules = [{
  #     "name": random_string,
  #     "project_ids": "",
  #     "rules": {
  #       "operator": "and",
  #       "groups": [
  #         {
  #           "operator": "and",
  #           "conditions": [
  #             {
  #               "rule_definition": "title_matches_regexp",
  #               "rule_value": "[\\u{1F300}-\\u{1F5FF}|\\u{1F1E6}-\\u{1F1FF}|\\u{2700}-\\u{27BF}|\\u{1F900}-\\u{1F9FF}|\\u{1F600}-\\u{1F64F}|\\u{1F680}-\\u{1F6FF}|\\u{2600}-\\u{26FF}]"
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #     "actions": [
  #       {
  #         "action_definition": "move_to_project",
  #         "action_value": p1.id.to_s
  #       }
  #     ]
  #   }]
  #   @team.rules = rules.to_json
  #   assert_nothing_raised do
  #     @team.save!
  #   end
  #   assert_equal 0, Project.find(p0.id).project_medias.count
  #   assert_equal 0, Project.find(p1.id).project_medias.count
  #   m = create_claim_media quote: '😊'
  #   create_project_media project: p0, media: m, smooch_message: { 'text' => '😊' }
  #   assert_equal 0, Project.find(p0.id).project_medias.count
  #   assert_equal 1, Project.find(p1.id).project_medias.count
  # end

  # TODO: Review by Sawy (change rule action)
  # test "should match rules with operators" do
  #   p1 = create_project team: @team
  #   p2 = create_project team: @team
  #   rules = []
  #   rules << {
  #     name: 'Rule 1',
  #     rules: {
  #       operator: 'and',
  #       groups: [
  #         {
  #           operator: 'or',
  #           conditions: [
  #             {
  #               rule_definition: 'contains_keyword',
  #               rule_value: 'test'
  #             },
  #             {
  #               rule_definition: 'contains_keyword',
  #               rule_value: 'foo'
  #             }
  #           ]
  #         },
  #         {
  #           operator: 'and',
  #           conditions: [
  #             {
  #               rule_definition: 'has_less_than_x_words',
  #               rule_value: 4
  #             },
  #             {
  #               rule_definition: 'contains_keyword',
  #               rule_value: 'bar'
  #             }
  #           ]
  #         },
  #       ]
  #     },
  #     actions: [
  #       {
  #         action_definition: 'move_to_project',
  #         action_value: p2.id
  #       }
  #     ]
  #   }
  #   @team.rules = rules.to_json
  #   @team.save!
  #   pm1 = create_project_media project: p1, smooch_message: { 'text' => '1 test bar' }, media: create_claim_media
  #   pm2 = create_project_media project: p1, smooch_message: { 'text' => '2 foo bar' }, media: create_claim_media
  #   pm3 = create_project_media project: p1, smooch_message: { 'text' => 'a b c d e f test foo' }, media: create_claim_media
  #   pm4 = create_project_media project: p1, smooch_message: { 'text' => 'test bar a b c d e f' }, media: create_claim_media
  #   assert_equal p2, pm1.project
  #   assert_equal p2, pm2.project
  #   assert_equal p1, pm3.project
  #   assert_equal p1, pm4.project
  #   rules[0][:rules][:operator] = 'or'
  #   rules[0][:rules][:groups][0][:operator] = 'and'
  #   rules[0][:rules][:groups][1][:operator] = 'or'
  #   @team.rules = rules.to_json
  #   @team.save!
  #   p1 = p1.reload
  #   pm1 = create_project_media project: p1, smooch_message: { 'text' => '1 test bar' }, media: create_claim_media
  #   pm2 = create_project_media project: p1, smooch_message: { 'text' => '2 foo bar' }, media: create_claim_media
  #   pm3 = create_project_media project: p1, smooch_message: { 'text' => 'a b c d e f test foo' }, media: create_claim_media
  #   pm4 = create_project_media project: p1, smooch_message: { 'text' => 'test bar a b c d e f' }, media: create_claim_media
  #   assert_equal p2, pm1.project
  #   assert_equal p2, pm2.project
  #   assert_equal p2, pm3.project
  #   assert_equal p2, pm4.project
  # end

  test "should match keyword with spaces with rule" do
    text = 'foo fake news bar'
    pm = create_project_media quote: text, team: @team, smooch_message: { 'text' => text }
    assert @team.contains_keyword(pm, 'fake news', nil)
    assert @team.contains_keyword(pm, 'foo', nil)
    assert @team.contains_keyword(pm, 'bar', nil)
    assert !@team.contains_keyword(pm, 'ba', nil)
    assert !@team.contains_keyword(pm, 'fak', nil)
    assert !@team.contains_keyword(pm, 'new', nil)
    assert !@team.contains_keyword(pm, 'oo', nil)
    assert !@team.contains_keyword(pm, 'ake new', nil)
    text = 'fake news'
    pm = create_project_media quote: text, team: @team, smooch_message: { 'text' => text }
    assert @team.contains_keyword(pm, 'fake news', nil)
    assert !@team.contains_keyword(pm, 'ake new', nil)
  end
end
