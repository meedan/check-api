require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
require 'sidekiq/testing'

class TeamTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
  end

  test "should match rule when report is paused" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media team: t
    pm2 = create_project_media project: p2
    assert_equal 0, p1.reload.project_medias.count
    assert_equal 1, p2.reload.project_medias.count
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
                "rule_definition": "report_is_paused",
                "rule_value": ""
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
    t.rules = rules.to_json
    t.save!
    r1 = create_report(pm1, { state: 'published' }, 'publish')
    r2 = create_report(pm2, { state: 'published' }, 'publish')
    assert_equal 0, p1.reload.project_medias.count
    assert_equal 1, p2.reload.project_medias.count
    r1.set_fields = { state: 'paused' }.to_json ; r1.action = 'pause' ; r1.save!
    r2.set_fields = { state: 'paused' }.to_json ; r2.action = 'pause' ; r2.save!
    assert_equal 2, p1.reload.project_medias.count
    assert_equal 0, p2.reload.project_medias.count
  end

  test "should match rules with operators 2" do
    create_verification_status_stuff
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    rules = []
    rules << {
      name: 'Rule 1',
      rules: {
        operator: 'and',
        groups: [
          {
            operator: 'and',
            conditions: [
              {
                rule_definition: 'title_contains_keyword',
                rule_value: 'test'
              },
              {
                rule_definition: 'status_is',
                rule_value: 'in_progress'
              }
            ]
          }
        ]
      },
      actions: [
        {
          action_definition: 'move_to_project',
          action_value: p2.id
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p1, quote: 'foo test'
    pm2 = create_project_media project: p1, quote: 'foo bar'
    pm3 = create_project_media project: p1, quote: 'bar test'

    s = pm1.last_status_obj
    s.status = 'In Progress'
    s.save!

    s = pm2.last_status_obj
    s.status = 'In Progress'
    s.save!

    s = pm3.last_status_obj
    s.status = 'Verified'
    s.save!
    assert_equal p2, pm1.reload.project
    assert_equal p1, pm2.reload.project
    assert_equal p1, pm3.reload.project
  end

  test "should match rules with operators 3" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    rules = []
    rules << {
      name: 'Rule 1',
      rules: {
        operator: 'and',
        groups: [
          {
            operator: 'and',
            conditions: [
              {
                rule_definition: 'title_contains_keyword',
                rule_value: 'test'
              },
              {
                rule_definition: 'tagged_as',
                rule_value: 'foo'
              }
            ]
          }
        ]
      },
      actions: [
        {
          action_definition: 'move_to_project',
          action_value: p2.id
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p1, quote: 'foo test'
    pm2 = create_project_media project: p1, quote: 'foo bar'
    pm3 = create_project_media project: p1, quote: 'bar test'

    create_tag tag: 'foo', annotated: pm1
    create_tag tag: 'foo', annotated: pm2
    create_tag tag: 'bar', annotated: pm3

    assert_equal p2, pm1.reload.project
    assert_equal p1, pm2.reload.project
    assert_equal p1, pm3.reload.project
  end

  test "should match rules with operators 4" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    rules = []
    rules << {
      name: 'Rule 1',
      rules: {
        operator: 'and',
        groups: [
          {
            operator: 'and',
            conditions: [
              {
                rule_definition: 'title_contains_keyword',
                rule_value: 'test'
              },
              {
                rule_definition: 'report_is_published',
                rule_value: ''
              }
            ]
          }
        ]
      },
      actions: [
        {
          action_definition: 'move_to_project',
          action_value: p2.id
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p1, quote: 'foo test'
    pm2 = create_project_media project: p1, quote: 'foo bar'
    pm3 = create_project_media project: p1, quote: 'bar test'

    publish_report(pm1)
    publish_report(pm2)

    assert_equal p2, pm1.reload.project
    assert_equal p1, pm2.reload.project
    assert_equal p1, pm3.reload.project
  end

  test "should match rules with operators 5" do
    create_flag_annotation_type
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    rules = []
    rules << {
      name: 'Rule 1',
      rules: {
        operator: 'and',
        groups: [
          {
            operator: 'and',
            conditions: [
              {
                rule_definition: 'title_contains_keyword',
                rule_value: 'test'
              },
              {
                rule_definition: 'flagged_as',
                rule_value: { flag: 'spam', threshold: 3 }
              }
            ]
          }
        ]
      },
      actions: [
        {
          action_definition: 'move_to_project',
          action_value: p2.id
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p1, quote: 'foo test'
    pm2 = create_project_media project: p1, quote: 'foo bar'
    pm3 = create_project_media project: p1, quote: 'bar test'

    data = valid_flags_data(false)
    data[:flags]['spam'] = 3
    create_flag set_fields: data.to_json, annotated: pm1
    create_flag set_fields: data.to_json, annotated: pm2
    data[:flags]['spam'] = 1
    create_flag set_fields: data.to_json, annotated: pm3

    assert_equal p2, pm1.reload.project
    assert_equal p1, pm2.reload.project
    assert_equal p1, pm3.reload.project
  end

  test "should not match rules" do
    create_verification_status_stuff
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    rules = []
    rules << {
      name: 'Rule 1',
      rules: {
        operator: 'and',
        groups: [
          {
            operator: 'and',
            conditions: [
              {
                rule_definition: 'title_contains_keyword',
                rule_value: 'test'
              },
            ]
          }
        ]
      },
      actions: [
        {
          action_definition: 'move_to_project',
          action_value: p2.id
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p1, quote: 'foo test'
    assert_equal p2, pm1.reload.project
    pm1.project_id = p1.id
    pm1.save!
    assert_equal p1, pm1.reload.project
    s = pm1.last_status_obj
    s.status = 'In Progress'
    s.save!
    assert_equal p1, pm1.reload.project
  end

  test "should not have rules with blank names or duplicated names" do
    t = create_team
    rule1 = {
      name: 'Rule 1',
      rules: {
        operator: 'and',
        groups: [
          {
            operator: 'and',
            conditions: [
              {
                rule_definition: 'title_contains_keyword',
                rule_value: 'test'
              },
            ]
          }
        ]
      },
      actions: [
        {
          action_definition: 'move_to_project',
          action_value: 1
        }
      ]
    }
    rule2 = rule1.clone
    t.rules = [rule1, rule2].to_json
    assert_raises ActiveRecord::RecordInvalid do
      t.save!
    end
    rule1[:name] = ''
    rule2[:name] = 'Rule 2'
    t.rules = [rule1, rule2].to_json
    assert_raises ActiveRecord::RecordInvalid do
      t.save!
    end
    rule1[:name] = 'Rule 1'
    rule2[:name] = 'Rule 2'
    t.rules = [rule1, rule2].to_json
    assert_nothing_raised do
      t.save!
    end
  end

  test "should match rule by language" do
    at = create_annotation_type annotation_type: 'language'
    create_field_instance name: 'language', annotation_type_object: at
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media team: t
    pm2 = create_project_media project: p2
    pm3 = create_project_media team: t
    assert_equal 0, p1.reload.project_medias.count
    assert_equal 1, p2.reload.project_medias.count
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
                "rule_definition": "item_language_is",
                "rule_value": "pt"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p1.id
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    create_dynamic_annotation annotated: pm1, annotation_type: 'language', set_fields: { language: 'pt' }.to_json
    create_dynamic_annotation annotated: pm2, annotation_type: 'language', set_fields: { language: 'pt' }.to_json
    a = create_dynamic_annotation annotated: pm3, annotation_type: 'language', set_fields: { language: 'es' }.to_json
    assert_equal 2, p1.reload.project_medias.count
    assert_equal 0, p2.reload.project_medias.count
    a = Dynamic.find(a.id)
    a.set_fields = { language: 'pt' }.to_json
    a.save!
    assert_equal 3, p1.reload.project_medias.count
    assert_equal 0, p2.reload.project_medias.count
  end

  test "should get custom status" do
    t = create_team
    pm = ProjectMedia.new team: t

    # Test core statuses first
    I18n.locale = 'pt'
    assert_equal 'Em andamento', pm.status_i18n(:in_progress)
    I18n.locale = 'en'
    assert_equal 'In Progress', pm.status_i18n(:in_progress)
    assert_equal 'Em andamento', pm.status_i18n(:in_progress, { locale: 'pt' })

    # Test custom statuses now
    value = {
      "label": "Custom Status Label",
      "active": "in_progress",
      "default": "unstarted",
      "statuses": [
        {
          "id": "unstarted",
          "style": {
            "color": "blue"
          },
          "locales": {
            "en": {
              "label": "Unstarted",
              "description": "An item that did not start yet"
            },
            "pt": {
              "label": "Não iniciado ainda",
              "description": "Um item que ainda não começou a ser verificado"
            }
          }
        },
        {
          "id": "in_progress",
          "style": {
            "color": "yellow"
          },
          "locales": {
            "en": {
              "label": "Working on it",
              "description": "We are working on it"
            },
            "pt": {
              "label": "Estamos trabalhando nisso",
              "description": "Estamos trabalhando nisso"
            }
          }
        }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!

    I18n.locale = 'pt'
    assert_equal 'Estamos trabalhando nisso', pm.status_i18n(:in_progress)
    I18n.locale = 'en'
    assert_equal 'Working on it', pm.status_i18n(:in_progress)
    assert_equal 'Estamos trabalhando nisso', pm.status_i18n(:in_progress, { locale: 'pt' })
    assert_equal 'Working on it', pm.status_i18n(:in_progress, { locale: 'es' })
  end

  test "should not save custom verification statuses if identifier format is invalid" do
    create_verification_status_stuff
    t = create_team
    value = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: 'Custom Status 1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: 'Custom Status 2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should validate language format" do
    t = create_team
    t.set_language nil
    t.save!
    ['pT', 'portuguese'].each do |l|
      assert_raises ActiveRecord::RecordInvalid do
        t.language = l
        t.save!
      end
      assert_nil t.reload.get_language
    end
    ['pt', 'bho', 'pt_BR', 'pt-BR', 'zh-Hans'].each do |l|
      assert_nothing_raised do
        t.language = l
        t.save!
      end
      assert_equal l, t.reload.get_language
    end
  end

  test "should validate languages format" do
    t = create_team
    t.set_languages nil
    t.save!
    ['pT', 'portuguese'].each do |l|
      assert_raises ActiveRecord::RecordInvalid do
        t.languages = ['en', l]
        t.save!
      end
      assert_nil t.reload.get_languages
    end
    ['pt', 'bho', 'pt_BR', 'pt-BR', 'zh-Hans'].each do |l|
      assert_nothing_raised do
        t.languages = ['en', l]
        t.save!
      end
      assert_equal ['en', l], t.reload.get_languages
    end
  end

  test "should match rule by user" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u
    assert_equal 0, p.reload.project_medias.count
    assert_equal 0, p.reload.medias_count
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
                "rule_definition": "item_user_is",
                "rule_value": u.id.to_s
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
    create_project_media team: t, user: u
    create_project_media team: t
    create_project_media user: u
    assert_equal 1, p.reload.project_medias.count
    assert_equal 1, p.reload.medias_count
  end

  test "should set default language when creating team" do
    t = create_team
    assert_equal 'en', t.get_language
    assert_equal ['en'], t.get_languages
  end

  test 'should set and get language detection configuration' do
    t = create_team
    assert t.reload.get_language_detection
    t.language_detection = false
    t.save!
    assert !t.reload.get_language_detection
  end

  test "should match rule when item is read" do
    RequestStore.store[:skip_cached_field_update] = false
    RequestStore.store[:skip_delete_for_ever] = true
    t = create_team
    p = create_project team: t
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u
    assert_equal 0, p.reload.project_medias.count
    assert_equal 0, p.reload.medias_count
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
                "rule_definition": "item_is_read",
                "rule_value": ""
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
                "rule_definition": "item_user_is",
                "rule_value": u2.id.to_s
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
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media team: t, user: u2
    pm2 = create_project_media team: t, user: u2
    pm3 = create_project_media user: u2
    [pm1, pm2, pm3].each { |pm| pm.archived = false ; pm.save! }
    ProjectMediaUser.create! project_media: pm1, user: create_user, read: true
    ProjectMediaUser.create! project_media: pm3, user: create_user, read: true

    assert_equal 0, pm1.reload.archived
    assert_equal 0, pm2.reload.archived
    assert_equal 0, pm3.reload.archived
    assert_equal 1, p.reload.project_medias.count
    assert_equal 1, p.reload.medias_count
  end

  test "should create default fieldsets when team is created" do
    t = create_team
    assert_not_nil t.reload.get_fieldsets
  end

  test "should validate fieldsets" do
    t = create_team
    [
      { foo: 'bar' },
      'foo',
      [{ identifier: 'foo' }],
      [{ identifier: 'foo', singular: 'foo' }],
      [{ identifier: 'foo', plural: 'foos' }],
      [{ singular: 'foo', plural: 'foos' }],
      [{ singular: 'foo', plural: 'foos', identifier: 'Foo Bar' }]
    ].each do |fieldsets|
      assert_raises ActiveRecord::RecordInvalid do
        t.set_fieldsets fieldsets
        t.save!
      end
    end
  end

  test "should match rule by task answer" do
    RequestStore.store[:skip_cached_field_update] = false
    create_task_stuff
    t = create_team
    tt = create_team_task team_id: t.id, task_type: 'single_choice'
    p = create_project team: t
    pm = create_project_media team: t
    assert_equal 0, p.reload.project_medias.count
    assert_equal 0, p.reload.medias_count
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
                "rule_definition": "field_from_fieldset_tasks_value_is",
                "rule_value": { team_task_id: tt.id, value: 'Foo' }
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
    tk = pm.get_annotations('task').first.load
    tk.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: { selected: 'Bar' }.to_json }.to_json }.to_json
    tk.save!
    assert_equal 0, p.reload.project_medias.count
    assert_equal 0, p.reload.medias_count
    tk = Task.find(tk.id)
    tk.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: { selected: 'Foo' }.to_json }.to_json }.to_json
    tk.save!
    assert_equal 1, p.reload.project_medias.count
    assert_equal 1, p.reload.medias_count
  end

  test "should match rule by assignment" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    p = create_project team: t
    pm = create_project_media team: t
    assert_equal 0, p.reload.project_medias.count
    assert_equal 0, p.reload.medias_count
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
                "rule_definition": "item_is_assigned_to_user",
                "rule_value": u.id.to_s
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
    Assignment.create! assigned: pm.last_status_obj.becomes(Annotation), assigner: create_user, user: u
    assert_equal 1, p.reload.project_medias.count
    assert_equal 1, p.reload.medias_count
  end

  test "should match rule by text task answer" do
    RequestStore.store[:skip_cached_field_update] = false
    create_task_stuff
    t = create_team
    tt = create_team_task team_id: t.id, task_type: 'free_text'
    p = create_project team: t
    pm = create_project_media team: t
    assert_equal 0, p.reload.project_medias.count
    assert_equal 0, p.reload.medias_count
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
                "rule_definition": "field_from_fieldset_tasks_value_contains_keyword",
                "rule_value": { team_task_id: tt.id, value: 'foo,bar' }
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
    tk = pm.get_annotations('task').first.load
    tk.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'test test' }.to_json }.to_json
    tk.save!
    assert_equal 0, p.reload.project_medias.count
    assert_equal 0, p.reload.medias_count
    tk = Task.find(tk.id)
    tk.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'test foo test' }.to_json }.to_json
    tk.save!
    assert_equal 1, p.reload.project_medias.count
    assert_equal 1, p.reload.medias_count
  end

  test "should allow default BotUser to be added on creation" do
    bu = create_bot_user(default: true, approved: true)
    bu_non_default = create_bot_user(default: false, approved: true)
    t = create_team
    assert t.team_bot_installations.collect(&:bot_user).include?(bu)
    assert !t.team_bot_installations.collect(&:bot_user).include?(bu_non_default)
  end

  test "checks for false item images are similar" do
    pm = create_project_media
    t = create_team
    assert !t.item_images_are_similar(pm, "blah", 1)
  end

  test "checks for false item titles are similar" do
    pm = create_project_media
    t = create_team
    assert !t.item_titles_are_similar(pm, "blah", 1)
  end

  test "checks for true items are similar" do
    pm = create_project_media
    t = create_team
    pm.alegre_similarity_thresholds = {1 => {"test" => 1}}
    assert t.items_are_similar("test", pm, "blah", 1)
  end

  test "should match rule by title with spaces" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
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
                "rule_definition": "title_contains_keyword",
                "rule_value": "Foo Bar, Bar Foo"
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
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_medias.count
    assert_equal 0, Project.find(p1.id).project_medias.count
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","title":"Bar Foo","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    create_project_media project: p0, media: nil, url: url
    assert_equal 0, Project.find(p0.id).project_medias.count
    assert_equal 1, Project.find(p1.id).project_medias.count
  end

  test "should not match rule by number of words if request is empty" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
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
          "action_definition": "move_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_medias.count
    assert_equal 0, Project.find(p1.id).project_medias.count
    create_project_media project: p0
    assert_equal 1, Project.find(p0.id).project_medias.count
    assert_equal 0, Project.find(p1.id).project_medias.count
  end

  test "should duplicate team with tags and rules" do
    t = create_team
    create_tag_text team: t, text: 'new-tag'
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
                "rule_definition": "item_is_assigned_to_user",
                "rule_value": "3"
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
    assert_nothing_raised do
      copy = Team.duplicate(t)
      assert_equal ['new-tag'], copy.tag_texts.map(&:text)
      assert_equal 1, copy.get_rules.size
      assert_equal rules.first[:name], copy.get_rules.first['name']
    end
  end

  test "should duplicate team with Bots" do
    setup_smooch_bot(true)
    alegre_bot = create_alegre_bot(name: "alegre", login: "alegre")
    alegre_bot.approve!
    alegre_bot.install_to!(@team)
    tbi = TeamBotInstallation.where(team: @team)
    assert_equal ['alegre', 'smooch'], tbi.map(&:user).map(&:login).sort
    duplicate_team = nil
    assert_nothing_raised do
      duplicate_team = Team.duplicate(@team)
    end
    assert_not_nil duplicate_team
    tbi = TeamBotInstallation.where(team: duplicate_team)
    assert_equal ['alegre'], tbi.map(&:user).map(&:login)
  end

  test "should duplicate team with non english default language" do
    t1 = create_team
    t1.set_languages = ['fr']
    t1.set_language = 'fr'
    t1.save!
    t2 = Team.duplicate(t1)
    assert_equal ['fr'], t2.get_languages
    assert_equal 'fr', t2.get_language
  end

  test "should delete team and partition" do
    t = create_team
    assert_difference 'Team.count', -1 do
      t.destroy_partition_and_team!
    end
  end

  test "should match rule and add tag" do
    t = create_team
    create_tag_text text: 'test', team_id: t.id
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
                "rule_definition": "title_contains_keyword",
                "rule_value": "Foo"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "test"
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm = create_project_media team: t, media: nil, quote: 'Foo'
    assert_equal ['test'], pm.get_annotations('tag').map(&:load).map(&:tag_text)
  end

  test "should match rule by description" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
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
                "rule_definition": "title_contains_keyword",
                "rule_value": "test"
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
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_medias.count
    assert_equal 0, Project.find(p1.id).project_medias.count
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","description":"this is a test","title":"foo","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    create_project_media project: p0, media: nil, url: url
    assert_equal 0, Project.find(p0.id).project_medias.count
    assert_equal 1, Project.find(p1.id).project_medias.count
  end

  test "should update reports when status is changed at team level" do
    create_verification_status_stuff
    t = create_team
    value = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
      ]
    }
    assert_nothing_raised do
      t.set_media_verification_statuses(value)
      t.save!
    end
    pm = create_project_media team: t
    r = publish_report(pm)
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'paused' }.to_json
    r.action = 'pause'
    r.save!
    s = pm.last_verification_status_obj
    s.status = '2'
    s.save!
    assert_equal 'Custom Status 2', r.reload.data.dig('options', 'status_label')
    t = Team.find(t.id)
    value[:statuses][1][:locales][:en][:label] = 'Custom Status 2 Changed'
    t.media_verification_statuses = value
    t.save!
    assert_equal 'Custom Status 2 Changed', r.reload.data.dig('options', 'status_label')
  end

  test "should add trashed link to duplicated team" do
    m = create_valid_media
    t1 = create_team
    t2 = Team.duplicate(t1)
    pm = create_project_media media: m, team: t1
    pm = ProjectMedia.find(pm.id)
    pm.archived = 1
    pm.save!
    create_project_media media: m, team: t2
  end

  test "should return slack notifications as JSON schema" do
    t = create_team
    create_project team: t
    create_project team: t
    assert_not_nil t.slack_notifications_json_schema
  end

  test "should map team tasks on saved searches when duplicating team" do
    t1 = create_team
    tt1 = create_team_task team: t1
    ss1 = create_saved_search team: t1, filters: { 'team_tasks' => [{ 'id' => tt1.id.to_s, 'task_type' => 'free_text', 'response' => 'ANY_VALUE' }] }
    t2 = Team.duplicate(t1)
    tt2 = t2.team_tasks.first
    ss2 = t2.saved_searches.first
    assert_equal tt2.id.to_s, ss2.filters.dig('team_tasks', 0, 'id')
  end

  test "should have a default folder" do
    t = create_team
    assert_not_nil t.default_folder
  end

  test "should convert conditional info of team tasks when duplicating a team" do
    t1 = create_team
    tt1 = create_team_task team_id: t1.id
    tt2 = create_team_task team_id: t1.id, conditional_info: { selectedConditional: 'is...', selectedFieldId: tt1.id, selectedCondition: 'The Beatles' }.to_json
    t2 = Team.duplicate(t1)
    tt3 = TeamTask.where.not(conditional_info: nil).where(team_id: t2.id).last
    tt4 = TeamTask.find(JSON.parse(tt3.conditional_info)['selectedFieldId'])
    assert_equal t2, tt4.team
  end

  test "should return number of items" do
    t = create_team
    single = create_project_media team: t
    main = create_project_media team: t
    suggested = create_project_media team: t
    confirmed = create_project_media team: t
    create_relationship source_id: main.id, target_id: suggested.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: main.id, target_id: confirmed.id, relationship_type: Relationship.confirmed_type
    assert_equal 3, t.reload.medias_count
  end

  test "should default to Rails cache for data report if monthly team statistics not present" do
    t = create_team
    assert_nil t.data_report

    Rails.cache.write("data:report:#{t.id}", [{ 'Month' => 'Jan 2022', 'Search' => 1, 'Foo' => 2 }])
    assert_equal([{ 'Month' => '1. Jan 2022', 'Search' => 1, 'Foo' => 2 }], t.data_report)
  end

  test "should return data report with chronologically ordered items, preferring the MonthlyTeamStatistics when present" do
    t = create_team(name: 'Test team')
    assert_nil t.data_report

    Rails.cache.write("data:report:#{t.id}", [{ 'Month' => 'Jan 2022', 'Unique users' => 200 }])

    create_monthly_team_statistic(team: t, start_date: DateTime.new(2022, 2, 1), unique_users: 3)
    create_monthly_team_statistic(team: t, start_date: DateTime.new(2022, 1, 1), unique_users: 2)

    data_report = t.data_report
    first_stat = data_report.first

    assert_equal 2, data_report.length
    assert_equal '1. Jan 2022', first_stat['Month']
    assert_equal 'Test team', first_stat['Org']
    assert_equal 2, first_stat['Unique users']
  end

  test "should have feeds" do
    t = create_team
    f = create_feed
    f.teams << t
    assert_equal [f], t.feeds
  end

  test "should return if belongs to feed" do
    f = create_feed
    t = create_team
    assert !t.is_part_of_feed?(f.id)
    f.teams << t
    assert t.is_part_of_feed?(f.id)
  end

  test "should return teams that share feeds" do
    t1 = create_team
    t2 = create_team
    t3 = create_team
    t4 = create_team
    create_feed team: nil
    f1 = create_feed team: nil
    f1.teams << t1
    f1.teams << t2
    f2 = create_feed team: nil
    f2.teams << t1
    f2.teams << t3
    f3 = create_feed team: nil
    f3.teams << t2
    f3.teams << t3
    f3.teams << t4
    assert_equal [t1, t2, t3].sort, t1.shared_teams.sort
  end

  test "should return number of teams in a feed" do
    f = create_feed team: nil
    assert_equal 0, f.reload.teams_count
    f.teams << create_team
    assert_equal 1, f.reload.teams_count
    f.teams << create_team
    assert_equal 2, f.reload.teams_count
  end

  test "should update fact-check and reports after delete existing language" do
    setup_elasticsearch
    create_report_design_annotation_type
    t = create_team
    t.set_languages(["en", "ar", "fr"])
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
      with_current_user_and_team(u, t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      cd = create_claim_description project_media: pm, disable_es_callbacks: false
      fc = create_fact_check claim_description: cd, language: 'fr'
      fields = { state: 'published', options: { language: 'fr', image: '' } }.to_json
      d = create_dynamic_annotation annotation_type: 'report_design', set_fields: fields, action: 'save', annotated: pm
      assert_equal 'fr', fc.language
      sleep 2
      result = $repository.find(get_es_id(pm))
      assert_equal ['fr'], result['fact_check_languages']
      # Verify delete language (workspace with multi-language after deletion)
      t.set_languages(["en", "ar"])
      t.save!
      assert_equal 'und', fc.reload.language
      data = d.reload.data.with_indifferent_access
      assert_equal 'und', data[:options][:language]
      sleep 2
      result = $repository.find(get_es_id(pm))
      assert_equal ['und'], result['fact_check_languages']
      # Verify delete language (workspace with one language after deletion)
      pm = create_project_media team: t, disable_es_callbacks: false
      cd = create_claim_description project_media: pm, disable_es_callbacks: false
      fc = create_fact_check claim_description: cd, language: 'ar'
      fields = { state: 'published', options: { language: 'ar', image: '' } }.to_json
      d = create_dynamic_annotation annotation_type: 'report_design', set_fields: fields, action: 'save', annotated: pm
      assert_equal 'ar', fc.language
      sleep 2
      result = $repository.find(get_es_id(pm))
      assert_equal ['ar'], result['fact_check_languages']
      t.set_languages(["en"])
      t.save!
      assert_equal 'en', fc.reload.language
      data = d.reload.data.with_indifferent_access
      assert_equal 'en', data[:options][:language]
      sleep 2
      result = $repository.find(get_es_id(pm))
      assert_equal ['en'], result['fact_check_languages']
    end
  end
end
