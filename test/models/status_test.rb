require_relative '../test_helper'

class StatusTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create status" do
    assert_difference 'Status.length' do
      create_status
    end
  end

  test "should set type automatically" do
    st = create_status
    assert_equal 'status', st.annotation_type
  end

  test "should have status" do
    assert_no_difference 'Status.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_status(status: nil)
        create_status(status: '')
      end
    end
  end

  test "should have annotations" do
    s1 = create_project_source
    assert_equal [], s1.annotations
    s2 = create_project_source
    assert_equal [], s2.annotations

    t1a = create_status annotated: nil
    assert_nil t1a.annotated
    t1b = create_status annotated: nil
    assert_nil t1b.annotated
    t2a = create_status annotated: nil
    assert_nil t2a.annotated
    t2b = create_status annotated: nil
    assert_nil t2b.annotated

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

  test "should create version when status is created" do
    st = nil
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      st = create_status(status: 'undetermined', annotated: pm)
    end
    assert_equal 1, st.versions.count
    v = st.versions.last
    assert_equal 'create', v.event
    assert_equal({"data"=>[{}, {"status"=>"undetermined"}], "annotator_type"=>[nil, "User"], "annotator_id"=>[nil, st.annotator_id], "annotated_type"=>[nil, "ProjectMedia"], "annotated_id"=>[nil, st.annotated_id], "annotation_type"=>[nil, "status"]}, v.changeset)
  end

  test "should create version when status is updated" do
    st = nil
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      st = create_status(status: 'undetermined', annotated: pm)
      assert_equal 1, st.versions.count
      st = Status.where(annotation_type: 'status').last
      st.status = 'verified'
      st.save!
      assert_equal 2, st.versions.count
    end
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({"data"=>[{"status"=>"undetermined"}, {"status"=>"verified"}]}, v.changeset)
  end

  test "should get columns as array" do
    assert_kind_of Array, Status.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, Status.columns_hash
  end

  test "should not be abstract" do
    assert_not Status.abstract_class?
  end

  test "should have content" do
    st = create_status
    assert_equal ['status'], JSON.parse(st.content).keys
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
    u = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u, role: 'editor'
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      st = create_status annotated: pm, annotator: nil, current_user: u, status: 'false'
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
    assert_no_difference 'Status.length' do
      assert_raise ActiveRecord::RecordInvalid do
        create_status status: 'invalid'
      end
    end
  end

  test "should not create status with invalid annotated type" do
    assert_no_difference 'Status.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_status(status: 'false', annotated: create_project)
      end
    end
  end

  test "should notify Slack when status is updated" do
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
      s.status = 'verified'; s.save!
      assert s.sent_to_slack
      # claim report
      m = create_claim_media project_id: p.id
      pm = create_project_media project: p, media: m
      s = create_status status: 'false', annotator: u, annotated: pm
      assert_not s.sent_to_slack
      s.status = 'verified'; s.save!
      assert s.sent_to_slack
    end
  end

  test "should validate status" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m

    assert_difference  'Status.length' do
      create_status annotated: pm, status: 'in_progress'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_status annotated: pm, status: '1'
    end

    value = { label: 'Test', default: '1', statuses: [{ id: '1', label: 'Analyzing', description: 'Testing', style: 'foo' }] }
    t.set_media_verification_statuses(value)
    t.save!

    assert_difference 'Status.length' do
      create_status annotated: pm, status: '1'
    end
  end

  test "should get default id" do
    t = create_team
    p = create_project team: t
    m = create_valid_media

    assert_equal 'undetermined', Status.default_id(m.reload, p.reload)

    value = { label: 'Test', default: '1', statuses: [{ id: '1', label: 'Analyzing', description: 'Testing', style: 'foo' }] }
    t.set_media_verification_statuses(value)
    t.save!

    assert_equal '1', Status.default_id(m.reload, p.reload)

    value = { label: 'Test', default: '', statuses: [{ id: 'first', label: 'Analyzing', description: 'Testing', style: 'bar' }] }
    t.set_media_verification_statuses(value)
    t.save!

    assert_equal 'first', Status.default_id(m.reload, p.reload)
    assert_equal 'undetermined', Status.default_id(m.reload)
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
    assert_difference 'Status.length' do
      s = create_status status: 'verified', annotated: pm, current_user: u, annotator: u
    end
    m.user = u; m.save!
    assert_difference 'Status.length' do
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
    assert_difference 'Status.length' do
      s = create_status status: 'verified', annotated: pm, current_user: u, annotator: u
    end
    p.user = u; p.save!
    assert_difference 'Status.length' do
      s = create_status status: 'verified', annotated: pm, current_user: u, annotator: u
    end
    Team.unstub(:current)
  end

  test "should normalize status" do
    s = nil
    assert_difference 'Status.length' do
      s = create_status status: 'Not Credible', annotated: create_project_source
    end
    assert_equal 'not_credible', s.reload.status
  end

  test "should display status label" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      statuses: [
        { id: '1', label: 'Foo', description: 'The meaning of this status', style: 'red' },
        { id: '2', label: 'Bar', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    s = create_status status: '1', annotated: pm
    assert_equal 'Foo', s.id_to_label('1')
    assert_equal 'Bar', s.id_to_label('2')
  end

  test "should create elasticsearch status" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media media: m, project: p, disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(pm.id)
    assert_equal Status.default_id(pm.media, pm.project), result.status
  end

  test "should update elasticsearch status" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media media: m, project: p, disable_es_callbacks: false
    st = create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(pm.id)
    assert_equal 'verified', result.status
  end

  test "should revert destroy status" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p, media: m
      s = Status.where(annotation_type: 'status', annotated_type: pm.class.to_s , annotated_id: pm.id).last
      s.status = 'false'; s.save!
      s.destroy
      assert_equal s.reload.status, Status.default_id(m.reload, p.reload)
      s.status = 'Not Applicable'; s.save!; s.reload
      s.status = 'false'; s.save!; s.reload
      s.status = 'verified'; s.save!
      assert_equal s.reload.status, 'verified'
      s.destroy
      assert_equal s.reload.status, 'false'
      s.destroy
      assert_equal s.reload.status, 'not_applicable'
      s.destroy
      assert_equal s.reload.status, Status.default_id(m.reload, p.reload)
      s.destroy
      assert_nil Status.where(id: s.id).last
    end
  end

  test "should protect attributes from mass assignment" do
    raw_params = { annotator: create_user, status: 'my comment' }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Status.create(params)
    end
  end

end
