require_relative '../test_helper'

class ProjectSourceTest < ActiveSupport::TestCase

  test "should create project source" do
    assert_difference 'ProjectSource.count' do
      create_project_source
    end
  end

  test "should get tags" do
    s = create_project_source
    t = create_tag annotated: s
    c = create_comment annotated: s
    assert_equal [t], s.tags
  end

  test "should get comments" do
    s = create_project_source
    t = create_tag annotated: s
    c = create_comment annotated: s
    assert_equal [c], s.comments
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
    pender_url = CONFIG['pender_host'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    assert_difference 'Account.count' do
      ps = create_project_source name: 'New source', url: url
      assert_includes ps.source.accounts.map(&:url), url
    end
  end

  test "should check if project source belonged to a previous project" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    p = create_project team: t
    p2 = create_project team: t
    with_current_user_and_team(u, t) do
      ps = create_project_source project: p
      assert ProjectSource.belonged_to_project(ps.id, p.id)
      ps.project = p2; ps.save!
      assert_equal p2, ps.project
      assert ProjectSource.belonged_to_project(ps.id, p.id)
    end
  end

end
