require_relative '../test_helper'

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
    pm = create_project_media project: p, current_user: u
    with_current_user_and_team(u, t) do
      assert_difference 'Comment.length' do
        create_comment annotated: pm, annotator: u
      end
    end
  end

  test "contributor should comment on other reports" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t
    pm = create_project_media project: p, user: u
    cu = create_user
    create_team_user team: t, user: cu, role: 'contributor'
    ju = create_user
    create_team_user team: t, user: ju, role: 'journalist'

    # create a comment with contributor user
    with_current_user_and_team(cu, t) do
      assert_difference 'Comment.length' do
        create_comment annotated: pm, annotator: cu
      end
    end

    # create a comment with journalist user
    with_current_user_and_team(ju, t) do
      assert_difference 'Comment.length' do
        create_comment annotated: pm, current_user: ju, annotator: ju
      end
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
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      c = create_comment(text: 'test', annotated: pm)
      assert_equal 1, c.versions.count
      v = c.versions.last
      assert_equal 'create', v.event
    end
  end

  test "should create version when comment is updated" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      c = create_comment(text: 'foo', annotated: pm, annotator: u)
      c = Comment.last
      c.text = 'bar'
      c.disable_es_callbacks = true
      c.save!
      assert_equal 2, c.versions.count
      v = PaperTrail::Version.last
      assert_equal 'update', v.event
      assert_equal({"data"=>[{"text"=>"foo"}, {"text"=>"bar"}]}, v.changeset)
    end
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

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u2, role: 'contributor'
    pm = create_project_media project: p
    u2 = User.find(u2.id)

    with_current_user_and_team(u2, t) do
      c = create_comment annotator: nil, annotated: pm
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

  test "journalist should destroy own notes" do
    u = create_user
    t = create_team
    p = create_project user: create_user, team: t
    create_team_user team: t, user: u, role: 'contributor'
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
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
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      c = create_comment annotator: u, annotated: pm
      assert c.sent_to_slack
      # claim media
      m = create_claim_media project_id: p.id
      c = create_comment annotator: u, annotated: pm
      assert c.sent_to_slack
    end
  end

  test "should notify Pusher when annotation is created" do
    c = create_comment annotated: create_project_media
    assert c.sent_to_pusher
  end

  test "should notify Pusher when annotation is destroyed" do
    c = create_comment annotated: create_project_media
    c.destroy
    assert c.sent_to_pusher
  end

  test "should have entities" do
    c = Comment.new
    assert_kind_of Array, c.entities
  end

  test "should extract Check URLs" do
    t1 = create_team slug: 'test'
    p1 = create_project team: t1
    p2 = create_project team: t1
    t2 = create_team slug: 'test2'
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    p3 = create_project team: t2
    pm3 = create_project_media project: p3
    text = "Please check reports #{CONFIG['checkdesk_client']}/test/project/#{p1.id}/media/#{pm1.id} and #{CONFIG['checkdesk_client']}/test/project/#{p2.id}/media/#{pm2.id} and #{CONFIG['checkdesk_client']}/test2/project/1/media/#{pm3.id} because they are nice"
    c = create_comment text: text, annotated: pm1
    assert_includes c.entity_objects, pm1
    assert_includes c.entity_objects, pm2
    refute_includes c.entity_objects, pm3
  end

  test "should protect attributes from mass assignment" do
    raw_params = { annotator: create_user, text: 'my comment' }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Comment.create(params)
    end
  end

  test "should have image" do
    c = nil
    assert_difference 'Comment.length' do
      c = create_comment file: 'rails.png'
    end
    assert_not_nil c.file
  end

  test "should not upload a file that is not an image" do
    assert_no_difference 'Comment.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_comment file: 'not-an-image.txt'
      end
    end
  end

  test "should not upload a big image" do
    assert_no_difference 'Comment.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_comment file: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small image" do
    assert_no_difference 'Comment.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_comment file: 'ruby-small.png'
      end
    end
  end

  test "should have public path" do
    t = create_comment file: 'rails.png'
    assert_match /^http/, t.public_path
  end

  test "should not upload a heavy image" do
    assert_no_difference 'Comment.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_comment file: 'rails-photo.jpg'
      end
    end
  end

  test "should create versions" do
    i = create_comment file: 'rails.png'
    assert_not_nil i.file.thumbnail
    assert_not_nil i.file.embed
  end

  test "should not upload corrupted file" do
    assert_no_difference 'Comment.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_comment file: 'corrupted-image.png'
      end
    end
  end

  test "should not upload if disk is full" do
    Comment.any_instance.stubs(:save!).raises(Errno::ENOSPC)
    assert_no_difference 'Comment.length' do
      assert_raises Errno::ENOSPC do
        create_comment file: 'rails.png'
      end
    end
    Comment.any_instance.unstub(:save!)
  end

  test "should not upload unsafe image (mocked)" do
    stub_configs({ 'clamav_service_path' => 'localhost:8080' }) do
      ClamAV::Client.stubs(:new).returns(MockedClamavClient.new('virus'))
      assert_no_difference 'Comment.length' do
        assert_raises ActiveRecord::RecordInvalid do
          create_comment file: 'rails.png'
        end
      end
      ClamAV::Client.unstub(:new)
    end
  end

  test "should upload safe image (mocked)" do
    stub_configs({ 'clamav_service_path' => 'localhost:8080' }) do
      ClamAV::Client.stubs(:new).returns(MockedClamavClient.new('success'))
      assert_difference 'Comment.length' do
        create_comment file: 'rails.png'
      end
      ClamAV::Client.unstub(:new)
    end
  end

  test "should create comment without image" do
    assert_difference 'Comment.length' do
      create_comment file: nil
    end
  end

  test "should create comment without text if there is image" do
    assert_difference 'Comment.length' do
      create_comment file: 'rails.png', text: nil
    end
  end

  test "should not create comment without text if there is no image" do
    assert_no_difference 'Comment.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_comment file: nil, text: nil
      end
    end
  end

  test "should have image data" do
    c1 = create_comment file: 'rails.png'
    a1 = Annotation.find(c1.id).image_data
    assert a1.has_key?(:embed)
    assert a1.has_key?(:thumbnail)
    c2 = create_comment
    a2 = Annotation.find(c2.id).image_data
    assert_equal({}, a2)
  end

  test "should extract Check URLs inside brackets" do
    t = create_team slug: 'test'
    p = create_project team: t
    pm = create_project_media project: p
    text = "Please check this report [#{CONFIG['checkdesk_client']}/test/project/#{p.id}/media/#{pm.id}]"
    c = create_comment text: text, annotated: pm
    assert_includes c.entity_objects, pm
  end

  test "should get team for a source comment" do
    t = create_team
    s = create_source team: t
    c = create_comment annotated: s
    assert_equal [t.id], c.get_team
  end

  test "should notify Pusher when comment is created for source or media" do
    pm = create_project_media
    c = create_comment annotated: pm
    assert c.sent_to_pusher

    ps = create_project_source
    c = create_comment annotated: ps
    assert c.sent_to_pusher
  end

  test "should belong to a task" do
    t = create_task
    c = create_comment annotated: t
    assert_equal t, c.task
  end

  test "should have Slack message for task comment" do
    t = create_task
    c = create_comment annotated: t
    User.current = create_user
    assert_match I18n.t("slack.messages.task_comment", c.slack_params), c.slack_notification_message[:pretext]
    User.current = nil
  end
end
