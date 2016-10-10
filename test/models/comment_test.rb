require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SampleModel < ActiveRecord::Base
  has_annotations
end

class CommentTest < ActiveSupport::TestCase
  def setup
    super
    Comment.delete_index
    Comment.create_index
    sleep 1
  end

  test "should create comment" do
    assert_difference 'Comment.length' do
      create_comment(text: 'test')
    end
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'contributor'
    p = create_valid_media team: t, current_user: u
    assert_difference 'Comment.length' do
      create_comment annotated: p, current_user: u, annotator: u
    end
  end

  test "rejected user should not create comment" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, status: 'banned'
    assert_raise RuntimeError do
      create_comment current_user: u, annotator: u
    end
  end

  test "should set type automatically" do
    c = create_comment
    assert_equal 'comment', c.annotation_type
  end

  test "should have text" do
    assert_no_difference 'Comment.length' do
      assert_raise RuntimeError do
        create_comment(text: nil)
      end
      assert_raise RuntimeError do
        create_comment(text: '')
      end
    end
  end

  test "should have annotations" do
    s1 = SampleModel.create!
    assert_equal [], s1.annotations
    s2 = SampleModel.create!
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

    sleep 1

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
      c = create_comment(text: 'test')
    end
    assert_equal 1, c.versions.count
    v = c.versions.last
    assert_equal 'create', v.event
    assert_equal({ 'annotation_type' => ['', 'comment'], 'annotated_type' => ['', 'Source'], 'annotated_id' => ['', c.annotated_id], 'annotator_type' => ['', 'User'], 'annotator_id' => ['', c.annotator_id], 'text' => ['', 'test' ] }, JSON.parse(v.object_changes))
  end

  test "should create version when comment is updated" do
    c = create_comment(text: 'foo').reload
    c.text = 'bar'
    c.save
    assert_equal 2, c.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({ 'text' => ['foo', 'bar'] }, JSON.parse(v.object_changes))
  end

  test "should revert" do
    c = create_comment(text: 'Version 1')
    c.text = 'Version 2'; c.save
    c.text = 'Version 3'; c.save
    c.text = 'Version 4'; c.save
    assert_equal 4, c.versions.size

    c = c.reload
    c.revert
    assert_equal 'Version 3', c.text
    c = c.reload
    assert_equal 'Version 4', c.text

    c.revert_and_save
    assert_equal 'Version 3', c.text
    c = c.reload
    assert_equal 'Version 3', c.text

    c.revert
    assert_equal 'Version 2', c.text
    c.revert
    assert_equal 'Version 1', c.text
    c.revert
    assert_equal 'Version 1', c.text

    c.revert(-1)
    assert_equal 'Version 2', c.text
    c.revert(-1)
    assert_equal 'Version 3', c.text
    c.revert(-1)
    assert_equal 'Version 4', c.text
    c.revert(-1)
    assert_equal 'Version 4', c.text

    c = c.reload
    assert_equal 'Version 3', c.text
    c.revert_and_save(-1)
    c = c.reload
    assert_equal 'Version 4', c.text

    assert_equal 4, c.versions.size
  end

  test "should return whether it has an attribute" do
    c = create_comment
    assert c.has_attribute?(:text)
  end

  test "should have a single annotation type" do
    c = create_comment
    assert_equal 'annotation', c._type
  end

  test "should have context" do
    c = create_comment
    s = SampleModel.create
    assert_nil c.context
    c.context = s
    c.save
    assert_equal s, c.context
  end

  test "should get annotations from context" do
    context1 = SampleModel.create
    context2 = SampleModel.create
    annotated = SampleModel.create

    c1 = create_comment
    c1.context = context1
    c1.annotated = annotated
    c1.save

    c2 = create_comment
    c2.context = context2
    c2.annotated = annotated
    c2.save

    sleep 1

    assert_equal [c1.id, c2.id].sort, annotated.annotations.map(&:id).sort
    assert_equal [c1.id], annotated.annotations(nil, context1).map(&:id)
    assert_equal [c2.id], annotated.annotations(nil, context2).map(&:id)
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
    s1 = SampleModel.create!
    s2 = SampleModel.create!
    c1 = create_comment annotator: u1, annotated: s1
    c2 = create_comment annotator: u1, annotated: s1
    c3 = create_comment annotator: u1, annotated: s1
    c4 = create_comment annotator: u2, annotated: s1
    c5 = create_comment annotator: u2, annotated: s1
    c6 = create_comment annotator: u3, annotated: s2
    c7 = create_comment annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators
    assert_equal [u3].sort, s2.annotators
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
    create_team_user team: t, user: u2, role: 'contributor'
    m = create_valid_media team: t, current_user: u2
    c = create_comment annotated: m, annotator: nil, current_user: u2
    assert_equal u2, c.annotator
  end

  test "should not set annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'contributor'
    m = create_valid_media team: t, current_user: u2
    c = create_comment annotated: m, annotator: u1, current_user: u2
    assert_equal u1, c.annotator
  end

  test "should destroy comment" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    c = create_comment annotated: p, current_user: u, annotator: u
    c.current_user = u
    c.context_team = t
    assert_nothing_raised do
      c.destroy
    end
  end

  test "journalist should destroy own notes" do
    u = create_user
    t = create_team
    p = create_project user: create_user, team: t
    create_team_user team: t, user: u, role: 'contributor'
    m = create_valid_media project_id: p.id
    c = create_comment annotated: m, context: p, annotator: u
    c.current_user = u
    c.context_team = t
    c.destroy
  end

  test "should not destroy comment" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    c = create_comment annotated: p, current_user: u, annotator: u
    c.current_user = u
    c.context_team = create_team
    assert_raise RuntimeError do
      c.destroy
    end
  end

  test "should get team" do
    c = create_comment
    assert_nil c.current_team
    t = create_team
    p = create_project team: t
    c = create_comment context: p
    assert_equal t, c.current_team
  end

  test "should notify on Slack when comment is created" do
    t = create_team subdomain: 'test'
    u = create_user
    create_team_user team: t, user: u
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'http://test.slack.com'; t.set_slack_channel = '#test'; t.save!
    m = create_valid_media
    c = create_comment origin: 'http://test.localhost:3333', current_user: u, annotator: u, annotated: m, context: p
    assert c.sent_to_slack
  end
end
