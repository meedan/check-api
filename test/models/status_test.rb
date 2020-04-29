require_relative '../test_helper'

class StatusTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create status" do
    assert_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      create_status
    end
  end

  test "should set type automatically" do
    st = create_status
    assert_equal 'verification_status', st.annotation_type
  end

  test "should have status" do
    create_verification_status_stuff
    assert_no_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      assert_raises NoMethodError do
        create_status(status: nil)
        create_status(status: '')
      end
    end
  end

  test "should have annotations" do
    create_verification_status_stuff
    s1 = create_project_source
    assert_equal [], s1.annotations
    s2 = create_project_source
    assert_equal [], s2.annotations

    t1a = create_status
    t1b = create_status
    t2a = create_status
    t2b = create_status

    s1.add_annotation t1a
    t1b.annotated = s1
    t1b.save

    s2.add_annotation t2a
    t2b.annotated = s2
    t2b.save

    assert_equal s1, t1a.annotated
    assert_equal s1, t1b.annotated
    assert_equal [t1a.id, t1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, t2a.annotated
    assert_equal s2, t2b.annotated
    assert_equal [t2a.id, t2b.id].sort, s2.reload.annotations.map(&:id).sort
  end

  test "should create version when status is updated" do
    create_verification_status_stuff
    st = nil
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      st = create_status(status: 'undetermined', annotated: pm)
      assert_equal 1, st.get_field('verification_status_status').versions.count
      st = Dynamic.where(annotation_type: 'verification_status').last
      st.disable_es_callbacks = true
      st.status = 'verified'
      st.save!
      assert_equal 2, st.get_field('verification_status_status').versions.count
    end
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({"value"=>["undetermined", "verified"]}, v.changeset)
  end

  test "should get columns as array" do
    assert_kind_of Array, Dynamic.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, Dynamic.columns_hash
  end

  test "should not be abstract" do
    assert_not Dynamic.abstract_class?
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    ps1 = create_project_source
    ps2 = create_project_source
    Annotation.delete_all
    st1 = create_status annotator: u1, annotated: ps1
    st2 = create_status annotator: u1, annotated: ps1
    st3 = create_status annotator: u1, annotated: ps1
    st4 = create_status annotator: u2, annotated: ps1
    st5 = create_status annotator: u2, annotated: ps1
    st6 = create_status annotator: u3, annotated: ps2
    st7 = create_status annotator: u3, annotated: ps2

    assert_equal [u1.id, u2.id].sort, ps1.annotators.map(&:id).sort
    assert_equal [u3.id], ps2.annotators.map(&:id)
  end

  test "should set annotator if not set" do
    create_verification_status_stuff
    u = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u, role: 'editor'
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      st = create_status annotated: pm, annotator: nil, current_user: u, status: 'false', skip_check_ability: true
      assert_equal u, st.annotator
    end
  end

  test "should not set annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'editor'
    p = create_project team: t
    m = create_valid_media current_user: u2
    pm = create_project_media project: p, media: m
    st = create_status annotated: pm, annotator: u1, current_user: u2, status: 'false'
    assert_equal u1, st.annotator
  end

  test "should not create status with invalid value" do
    assert_no_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      assert_raise ActiveRecord::RecordInvalid do
        create_status status: 'invalid'
      end
    end
  end

  test "should notify Slack when status is updated" do
    create_verification_status_stuff
    if Bot::Slack.default.nil?
      b = Bot::Slack.new
      b.name = 'Slack Bot'
      b.save!
    end
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      p = create_project team: t
      m = create_valid_media
      pm = create_project_media project: p, media: m
      s = create_status status: 'false', annotator: u, annotated: pm
      assert_not s.sent_to_slack
      s = Dynamic.find(s.id)
      s.status = 'verified'; s.save!
      assert s.sent_to_slack
      # claim report
      m = create_claim_media project_id: p.id
      pm = create_project_media project: p, media: m
      s = create_status status: 'false', annotator: u, annotated: pm
      assert_not s.sent_to_slack
      s = Dynamic.find(s.id)
      s.status = 'verified'; s.save!
      assert s.sent_to_slack
    end
  end

  test "should validate status" do
    t = create_team
    p = create_project team: t
    pm = create_project_media

    assert_raises ActiveRecord::RecordInvalid do
      create_status annotated: pm, status: '1'
    end

    value = { label: 'Test', default: '1', active: '1', statuses: [{ id: '1', label: 'Analyzing', completed: '', description: 'Testing', style: 'foo' }] }
    t.set_media_verification_statuses(value)
    t.save!

    pm2 = create_project_media project: p
    assert_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      create_status annotated: pm2, status: '1'
    end
  end

  test "should get default id" do
    t = create_team
    t2 = create_team
    p = create_project team: t
    p2 = create_project team: t2
    pm = create_project_media

    assert_equal 'undetermined', Workflow::Workflow.options(pm, 'verification_status')[:default]

    value = { label: 'Test', active: '1', default: '1', statuses: [{ id: '1', label: 'Analyzing', completed: '', description: 'Testing', style: 'foo' }] }
    t.set_media_verification_statuses(value)
    t.save!

    pm = create_project_media project: p
    assert_equal '1', Workflow::Workflow.options(pm.reload, 'verification_status')[:default]

    value = { label: 'Test', active: 'first', default: 'first', statuses: [{ id: 'first', label: 'Analyzing', completed: '', description: 'Testing', style: 'bar' }] }
    t2.set_media_verification_statuses(value)
    t2.save!
    pm2 = create_project_media project: p2

    assert_equal 'first', Workflow::Workflow.options(pm2.reload, 'verification_status')[:default]
    assert_equal 'undetermined', Workflow::Workflow.options(create_project_media, 'verification_status')[:default]
  end

  test "journalist should change status of own report" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    Team.stubs(:current).returns(t)
    # Ticket #5373
    assert_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      s = create_status status: 'verified', annotated: pm, current_user: u, annotator: u
    end
    m.user = u; m.save!
    assert_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      s = create_status status: 'verified', annotated: pm, current_user: u, annotator: u
    end
    Team.unstub(:current)
  end

  test "journalist should change status of own project" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    Team.stubs(:current).returns(t)
    # Ticket #5373
    assert_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      s = create_status status: 'verified', annotated: pm, current_user: u, annotator: u
    end
    p.user = u; p.save!
    assert_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      s = create_status status: 'verified', annotated: pm, current_user: u, annotator: u
    end
    Team.unstub(:current)
  end

  test "should normalize status" do
    s = nil
    assert_difference "Dynamic.where(['annotation_type LIKE ?', '%status%']).count" do
      s = create_status status: 'Not Credible', annotated: create_project_source
    end
    assert_equal 'not_credible', s.reload.status
  end

  test "should protect attributes from mass assignment" do
    raw_params = { annotator: create_user, status: 'my comment' }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Dynamic.create(params)
    end
  end

  test "should define Slack message" do
    create_verification_status_stuff

    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u

    s = create_status status: 'false', annotated: pm, annotator: u
    s = Dynamic.find(s.id)
    s.status = 'verified'
    s.save!
    assert_match /verification status/, s.slack_notification_message[:pretext]

    u1 = create_user
    create_team_user user: u1, team: t
    u2 = create_user
    create_team_user user: u2, team: t
    s = create_status annotated: pm, annotator: u, status: 'false'

    s.assigned_to_ids = u2.id
    s.save!
    assert_match /assigned/, s.slack_notification_message[:pretext]

    s.assigned_to_ids = ""
    s.save!
    assert_match /unassigned/, s.slack_notification_message[:pretext]

    User.current = nil
  end

  test "should notify by e-mail when assignment changes" do
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!

    create_verification_status_stuff
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u

    u1 = create_user
    create_team_user user: u1, team: t
    u2 = create_user
    create_team_user user: u2, team: t
    s = create_status annotated: pm, annotator: u, status: 'in_progress'
    assert_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size', 1 do
      s.assign_user(u2.id)
    end

    assert_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size', 1 do
      s.assignments.last.destroy!
    end

    User.current = nil
  end

  test "should get status" do
    create_verification_status_stuff
    pm = create_project_media
    assert_kind_of Hash, Workflow::Workflow.get_status(pm, 'verification_status', 'in_progress')
  end
end
