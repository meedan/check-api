require_relative '../test_helper'

class ProjectSourceTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create project source" do
    assert_difference 'ProjectSource.count' do
      create_project_source
    end
  end

  test "should get collaborators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_project_source
    s2 = create_project_source
    c1 = create_comment annotator: u1, annotated: s1
    c2 = create_comment annotator: u1, annotated: s1
    c3 = create_comment annotator: u1, annotated: s1
    c4 = create_comment annotator: u2, annotated: s1
    c5 = create_comment annotator: u2, annotated: s1
    c6 = create_comment annotator: u3, annotated: s2
    c7 = create_comment annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.collaborators.sort
    assert_equal [u3].sort, s2.collaborators.sort
  end

  test "should have annotations" do
    s = create_project_source
    c1 = create_comment annotated: s
    c2 = create_comment annotated: s
    c3 = create_comment annotated: nil
    assert_equal [c1.id, c2.id].sort, s.reload.annotations.map(&:id).sort
  end

  test "should get team" do
    t = create_team
    p = create_project team: t
    s = create_project_source project: p
    assert_equal t, s.team
    assert_equal [t.id], s.get_team
    s.project = nil
    assert_equal [], s.get_team
  end

  test "should protect attributes from mass assignment" do
    raw_params = { project: create_project, source: create_source }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      ProjectSource.create(params)
    end
  end

  test "should set user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    s = create_source
    with_current_user_and_team(u, t) do
      ps = create_project_source project: p, source: s
      assert_equal u, ps.user
    end
  end

  test "should notify Slack when project source is created or edited" do
    t = create_team slug: 'test'
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    with_current_user_and_team(u, t) do
      s = create_source
      assert_not s.sent_to_slack
      s.name = 'change name'
      s.save!
      assert_not s.sent_to_slack
      ps = create_project_source project: p, source: s
      assert ps.sent_to_slack
      s.reload
      s.name = 'change name again'
      s.save!
      assert s.sent_to_slack
    end
  end

  test "should have a project and source" do
    assert_no_difference 'ProjectSource.count' do
      assert_raise ActiveRecord::RecordInvalid do
        create_project_source project: nil
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_project_source source: nil
      end
    end
  end

  test "should create source if name set" do
    assert_difference 'ProjectSource.count' do
      ps = create_project_source name: 'New source'
      assert_not_nil ps.source
    end
  end

  test "should create account if url set" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    assert_difference 'Account.count' do
      ps = create_project_source name: 'New source', url: url
      assert_includes ps.source.accounts.map(&:url), url
    end
  end

  test "should create source if url is set and name is blank" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    ps = create_project_source url: url, source: nil
    assert_not_nil ps.reload.source
  end

  test "should check if project source belonged to a previous project" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    p = create_project team: t
    p2 = create_project team: t
    with_current_user_and_team(u, t) do
      ps = create_project_source project: p
      assert ProjectSource.belonged_to_project(ps.id, p.id, t.id)
      ps.project = p2; ps.save!
      assert_equal p2, ps.project
      assert ProjectSource.belonged_to_project(ps.id, p.id, t.id)
    end
  end

  test "should get log" do
    s = create_source
    u = create_user
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    create_team_user user: u, team: t, role: 'owner'

    with_current_user_and_team(u, t) do
      ps = create_project_source project: p, source: s, user: u
      c = create_comment annotated: ps
      tg = create_tag annotated: ps
      f = create_flag annotated: ps
      s.name = 'update name'; s.skip_check_ability = true; s.save!
      ps.project_id = p2.id; ps.save!
      ps = ProjectSource.find(ps.id)
      assert_equal ["create_comment", "create_tag", "create_dynamic", "update_projectsource", "update_source"].sort, ps.get_versions_log.map(&:event_type).sort
      assert_equal 5, ps.get_versions_log_count
      c.destroy
      assert_equal 5, ps.get_versions_log_count
      tg.destroy
      assert_equal 5, ps.get_versions_log_count
      f.destroy
      assert_equal 5, ps.get_versions_log_count
    end
  end

  test "contributor should add tag to own source" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user user: u, team: t, role: 'contributor'
    with_current_user_and_team(u, t) do
      s = create_source
      ps = create_project_source project: p, source: s, user: u
      assert_difference 'Tag.length' do
        create_tag annotated: ps
      end
    end
  end

  test "should not create duplicated source" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '/","type":"profile"}}')

    t = create_team
    p = create_project team: t
    create_project_source project: p, name: 'Test', url: url
    assert_raises ActiveRecord::RecordInvalid do
      create_project_source project: p, name: 'Test 2', url: url
    end
  end

  test "should be formatted as json" do
    ps = create_project_source
    assert_not_nil ps.as_json
  end

  test "should create project source when account has empty data" do
    account = create_account
    account.annotations('metadata').last.destroy

    ps = ProjectSource.new user: create_user, project: create_project
    ps.disable_es_callbacks = true
    ps.url = account.url

    assert_difference 'ProjectSource.count' do
      ps.save!
    end
  end

  test "should raise error when try to create project source with invalid url" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://invalid-url.ee'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url }}).to_return(body: '{"type":"error","data":{"message":"The URL is not valid", "code":4}}')

    ps = ProjectSource.new user: create_user, project: create_project
    ps.url = 'http://invalid-url.ee'

    assert_raise ActiveRecord::RecordInvalid do
      ps.save!
    end
  end

  test "should query source" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    create_project_source
    create_project_source project: p1
    create_project_source project: p2
    assert_equal 2, CheckSearch.new({ show: ['sources'], team_id: t.id }.to_json).sources.size
    assert_equal 1, CheckSearch.new({ show: ['sources'], team_id: t.id, projects: [p1.id] }.to_json).sources.size
    assert_equal 1, CheckSearch.new({ show: ['sources'], team_id: t.id, projects: [p2.id] }.to_json).sources.size
  end
end
