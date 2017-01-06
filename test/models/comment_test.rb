require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CommentTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create comment" do
    assert_difference 'Comment.length' do
      create_comment(text: 'test')
    end
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    m = create_valid_media current_user: u
    pm = create_project_media project: p, media: m, current_user: u
    assert_difference 'Comment.length' do
      create_comment annotated: pm, current_user: u, annotator: u
    end
  end

  test "contributor should comment on other reports" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t
    m = create_valid_media current_user: u
    pm = create_project_media project: p, media: m,  current_user: u
    # create a comment with contributor user
    cu = create_user
    create_team_user team: t, user: cu, role: 'contributor'
    assert_difference 'Comment.count' do
      create_comment annotated: pm, current_user: cu, annotator: cu
    end
    # create a comment with journalist user
    ju = create_user
    create_team_user team: t, user: ju, role: 'journalist'
    assert_difference 'Comment.count' do
      create_comment annotated: pm, current_user: ju, annotator: ju
    end
  end

  test "rejected user should not create comment" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, status: 'banned'
    with_current_user_and_team(u, t) do
      assert_raise RuntimeError do
        create_comment annotator: u
      end
    end
  end

  test "should set type automatically" do
    c = create_comment
    assert_equal 'comment', c.annotation_type
  end

  test "should have text" do
    assert_no_difference 'Comment.length' do
      assert_raise ActiveRecord::RecordInvalid do
        create_comment(text: nil)
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_comment(text: '')
      end
    end
  end

  test "should have annotations" do
    s1 = create_project_source
    assert_equal [], s1.annotations
    s2 = create_project_source
    assert_equal [], s2.annotations

    c1a = create_comment annotated: nil
    assert_nil c1a.annotated
    c1b = create_comment annotated: nil
    assert_nil c1b.annotated
    c2a = create_comment annotated: nil
    assert_nil c2a.annotated
    c2b = create_comment annotated: nil
    assert_nil c2b.annotated

    s1.add_annotation c1a
    c1b.annotated = s1
    c1b.save

    s2.add_annotation c2a
    c2b.annotated = s2
    c2b.save

    assert_equal s1, c1a.annotated
    assert_equal s1, c1b.annotated
    assert_equal [c1a.id, c1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, c2a.annotated
    assert_equal s2, c2b.annotated
    assert_equal [c2a.id, c2b.id].sort, s2.reload.annotations.map(&:id).sort
  end

  test "should create version when comment is created" do
    c = nil
    assert_difference 'PaperTrail::Version.count', 3 do
      c = create_comment(text: 'test', annotated: create_source)
    end
    assert_equal 1, c.versions.count
    v = c.versions.last
    assert_equal 'create', v.event
    assert_equal({"data"=>["{}", "{\"text\"=>\"test\"}"], "annotator_type"=>["", "User"], "annotator_id"=>["", "#{c.annotator_id}"], "annotated_type"=>["", "Source"], "annotated_id"=>["", "#{c.annotated_id}"], "annotation_type"=>["", "comment"]}, JSON.parse(v.object_changes))
  end

  test "should create version when comment is updated" do
    c = create_comment(text: 'foo')
    c = Comment.last
    c.text = 'bar'
    c.save!
    assert_equal 2, c.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
      assert_equal({"data"=>["{\"text\"=>\"foo\"}", "{\"text\"=>\"bar\"}"]}, JSON.parse(v.object_changes))
  end

  test "should get columns as array" do
    assert_kind_of Array, Comment.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, Comment.columns_hash
  end

  test "should not be abstract" do
    assert_not Comment.abstract_class?
  end

  test "should have content" do
    c = create_comment
    assert_equal ['text'], JSON.parse(c.content).keys
  end

  test "should have annotators" do
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
    assert_equal [u1, u2].sort, s1.annotators.sort
    assert_equal [u3].sort, s2.annotators.sort
  end

  test "should get annotator" do
    c = create_comment
    assert_nil c.send(:annotator_callback, 'test@test.com')
    u = create_user(email: 'test@test.com')
    assert_equal u, c.send(:annotator_callback, 'test@test.com')
  end

  test "should get target id" do
    c = create_comment
    assert_equal 2, c.target_id_callback(1, [1, 2, 3])
  end

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u2, role: 'contributor'

    with_current_user_and_team(u2, t) do
      c = create_comment annotator: nil
      assert_equal u2, c.annotator
    end
  end

  test "should not set annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'contributor'
    c = create_comment annotator: u1
    assert_equal u1, c.annotator
  end

  test "should destroy comment" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        c.destroy
      end
    end
  end

  test "journalist should not destroy own notes" do
    u = create_user
    t = create_team
    p = create_project user: create_user, team: t
    create_team_user team: t, user: u, role: 'contributor'
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      assert_raise RuntimeError do
        c.destroy
      end
    end
  end

  test "should not destroy comment" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, current_user: u, annotator: u
    with_current_user_and_team(u, create_team) do
      assert_raise RuntimeError do
        c.destroy
      end
    end
  end

  test "should get team" do
    c = create_comment annotated: nil
    assert_nil c.current_team
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    c = create_comment annotated: pm
    assert_equal t, c.current_team
  end

  test "should notify on Slack when comment is created" do
    t = create_team subdomain: 'test'
    u = create_user
    create_team_user team: t, user: u
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    m = create_valid_media
    pm = create_project_media project: p, media: m
    with_current_user_and_team(u, t) do
      c = create_comment origin: 'http://test.localhost:3333', annotator: u, annotated: pm
      assert c.sent_to_slack
      # claim media
      m = create_claim_media project_id: p.id
      c = create_comment origin: 'http://test.localhost:3333', annotator: u, annotated: pm
      assert c.sent_to_slack
    end
  end

  test "should notify Pusher when annotation is created" do
    c = create_comment annotated: create_project_media
    assert c.sent_to_pusher
  end

  test "should have entities" do
    c = Comment.new
    assert_kind_of Array, c.entities
  end

  test "should extract Check URLs" do
    t1 = create_team subdomain: 'test'
    p1 = create_project team: t1
    p2 = create_project team: t1
    t2 = create_team subdomain: 'test2'
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    p3 = create_project team: t2
    pm3 = create_project_media project: p3
    text = "Please check reports http://test.localhost:3333/project/#{p1.id}/media/#{pm1.id} and http://test.localhost:3333/project/#{p2.id}/media/#{pm2.id} and http://test2.localhost:3333/project/1/media/#{pm3.id} because they are nice"
    c = create_comment text: text, annotated: pm1
    assert_includes c.entity_objects, pm1
    assert_includes c.entity_objects, pm2
    refute_includes c.entity_objects, pm3
  end

  test "should create elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    sleep 1
    result = CommentSearch.find(c.id, parent: pm.id)
    assert_equal c.id.to_s, result.id
  end

  test "should update elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    c.text = 'test-mod'; c.save!
    sleep 1
    result = CommentSearch.find(c.id, parent: pm.id)
    assert_equal 'test-mod', result.text
  end

end
