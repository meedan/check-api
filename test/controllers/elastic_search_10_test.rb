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
    pm = create_project_media team: t
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
      pm2 = create_project_media team: t
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
      results = CheckSearch.new({ fc_languages: ['en', 'fr'] }.to_json)
      assert_equal [pm.id, pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ fc_languages: ['fr', 'und'] }.to_json)
      assert_equal [pm3.id, pm4.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ keyword: 'claim', fc_languages: ['en', 'fr'] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
    end
  end

  test "should filter items by non project and read-unread" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media project: p, disable_es_callbacks: false
      pm3 = create_project_media team: t, quote: 'claim a', disable_es_callbacks: false
      results = CheckSearch.new({ projects: ['-1'] }.to_json)
      # result should return empty as now all items should have a project CHECK-1150
      assert_empty results.medias.map(&:id)
      results = CheckSearch.new({ projects: [p.id, '-1'] }.to_json)
      assert_equal [pm2.id], results.medias.map(&:id)
      results = CheckSearch.new({ keyword: 'claim', projects: ['-1'] }.to_json)
      assert_empty results.medias.map(&:id)
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
    pm1 = create_project_media project: p, user: u1
    pm2 = create_project_media project: p, user: u2
    pm3 = create_project_media project: p, user: u3
    pm4 = create_project_media project: p, user: u4
    sleep 2
    result = CheckSearch.new({ projects: [p.id], sort: 'creator_name', sort_type: 'asc' }.to_json, nil, t.id)
    assert_equal [pm1.id, pm2.id, pm3.id, pm4.id], result.medias.map(&:id)
    result = CheckSearch.new({ projects: [p.id], sort: 'creator_name', sort_type: 'desc' }.to_json, nil, t.id)
    assert_equal [pm4.id, pm3.id, pm2.id, pm1.id], result.medias.map(&:id)
  end
end
