require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class StatusTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create status" do
    pm = create_project_media
    Status.delete_all
    assert_difference 'Status.length' do
      create_status annotated: pm
    end
  end

  test "should set type automatically" do
    st = create_status
    assert_equal 'status', st.annotation_type
  end

  test "should have status" do
    pm = create_project_media
    Status.delete_all
    assert_no_difference 'Status.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_status(status: nil, annotated: pm)
        create_status(status: '', annotated: pm)
      end
    end
  end

  test "should have annotations" do
    s1 = create_project_media
    assert_equal 1, s1.annotations.count
    t0a = s1.annotations.last.id
    s2 = create_project_media
    assert_equal 1, s2.annotations.count
    t0b = s2.annotations.last.id
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
    assert_equal [t0a,t1a.id, t1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, t2a.annotated
    assert_equal s2, t2b.annotated
    assert_equal [t0b, t2a.id, t2b.id].sort, s2.reload.annotations.map(&:id).sort
  end

  test "should create version when status is created" do
    st = nil
    assert_difference 'PaperTrail::Version.count', 3 do
      st = create_status(status: 'credible')
    end
    assert_equal 1, st.versions.count
    v = st.versions.last
    assert_equal 'create', v.event
    assert_equal({"data"=>["{}", "{\"status\"=>\"credible\"}"], "annotator_type"=>["", "User"], "annotator_id"=>["", "#{st.annotator_id}"], "annotated_type"=>["", "Source"], "annotated_id"=>["", "#{st.annotated_id}"], "annotation_type"=>["", "status"]}, JSON.parse(v.object_changes))
  end

  test "should create version when status is updated" do
    create_status(status: 'slightly_credible')
    st = Status.last
    st.status = 'sockpuppet'
    st.save
    assert_equal 2, st.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({"data"=>["{\"status\"=>\"slightly_credible\"}", "{\"status\"=>\"sockpuppet\"}"]}, JSON.parse(v.object_changes))
  end

  test "should have context" do
    st = create_status
    s = create_source
    assert_nil st.context
    st.context = s
    st.save
    assert_equal s, st.context
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
    pm1 = create_project_media
    pm2 = create_project_media
    st1 = create_status annotator: u1, annotated: pm1
    st2 = create_status annotator: u1, annotated: pm1
    st3 = create_status annotator: u1, annotated: pm1
    st4 = create_status annotator: u2, annotated: pm1
    st5 = create_status annotator: u2, annotated: pm1
    st6 = create_status annotator: u3, annotated: pm2
    st7 = create_status annotator: u3, annotated: pm2
    assert_equal [u1, u2].sort, pm1.annotators.sort
    assert_equal [u3].sort, pm2.annotators.sort
  end

  test "should get annotator" do
    st = create_status
    assert_nil st.send(:annotator_callback, 'test@test.com')
    u = create_user(email: 'test@test.com')
    assert_equal u, st.send(:annotator_callback, 'test@test.com')
  end

  test "should get target id" do
    st = create_status
    assert_equal 2, st.target_id_callback(1, [1, 2, 3])
  end

  test "should set annotator if not set" do
    u = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u, role: 'editor'
    m = create_valid_media project_id: p.id, current_user: u
    st = create_status annotated: m.project_media, annotator: nil, current_user: u, status: 'false'
    assert_equal u, st.annotator
  end

  test "should not set annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'editor'
    m = create_valid_media team: t, current_user: u2
    st = create_status annotated: m.project_media, annotator: u1, current_user: u2, status: 'false'
    assert_equal u1, st.annotator
  end

  test "should not create status with invalid value" do
    pm = create_project_media
    Status.delete_all
    assert_no_difference 'Status.length' do
      assert_raise ActiveRecord::RecordInvalid do
        create_status status: 'invalid', annotated: pm
      end
    end
    assert_no_difference 'Status.length' do
      assert_raise ActiveRecord::RecordInvalid do
        create_status status: 'invalid', annotated: nil
      end
    end
    assert_difference 'Status.length' do
      create_status status: 'credible', annotated: pm
    end
    assert_difference 'Status.length' do
      create_status status: 'verified', annotated: nil
    end
  end

  test "should not create status with invalid annotated type" do
    assert_no_difference 'Status.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_status(status: 'false', annotated: create_project)
      end
    end
  end

  test "should get annotated type" do
    s = create_status
    assert_equal 'Source', s.annotated_type_callback('source')
  end

  test "should notify Slack when status is created" do
    t = create_team subdomain: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s = create_status status: 'false', origin: 'http://test.localhost:3333', current_user: u, annotator: u, annotated: pm
    assert s.sent_to_slack
    # claim report
    m = create_claim_media project_id: p.id
    s = create_status status: 'false', origin: 'http://test.localhost:3333', current_user: u, annotator: u, annotated: m.project_media
    assert s.sent_to_slack
  end

  test "should validate status" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m

    assert_difference('Status.length') { create_status annotated: pm, status: 'in_progress' }
    assert_raises(ActiveRecord::RecordInvalid) { create_status annotated: pm, status: '1' }

    value = { label: 'Test', default: '1', statuses: [{ id: '1', label: 'Analyzing', description: 'Testing', style: 'foo' }] }
    t.set_media_verification_statuses(value)
    t.save!

    assert_difference('Status.length') { create_status annotated: pm, status: '1' }
    assert_raises(ActiveRecord::RecordInvalid) { create_status annotated: pm, status: 'in_progress' }

    assert_difference('Status.length') { create_status annotated: pm, status: 'in_progress' }
    assert_raises(ActiveRecord::RecordInvalid) { create_status annotated: pm, status: '1' }
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
    # Ticket #5373
    assert_difference 'Status.length' do
      s = create_status status: 'verified', annotated: pm, current_user: u, context_team: t, annotator: u
    end
    m.user = u; m.save!
    assert_difference 'Status.length' do
      s = create_status status: 'verified', annotated: pm, current_user: u, context_team: t, annotator: u
    end
  end

  test "journalist should change status of own project" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    # Ticket #5373
    assert_difference 'Status.length' do
      s = create_status status: 'verified', annotated: pm, current_user: u, context_team: t, annotator: u
    end
    p.user = u; p.save!
    assert_difference 'Status.length' do
      s = create_status status: 'verified', annotated: pm, current_user: u, context_team: t, annotator: u
    end
  end

  test "should normalize status" do
    s = nil
    assert_difference 'Status.length' do
      s = create_status status: 'Not Credible'
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

end
