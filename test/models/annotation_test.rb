require_relative '../test_helper'

class AnnotationTest < ActiveSupport::TestCase
  test "should not create generic annotation" do
    assert_no_difference 'Annotation.count' do
      assert_raises RuntimeError do
        create_annotation annotation_type: nil
      end
    end
  end

  test "should have empty content by default" do
    assert_equal '{}', Annotation.new.content
  end

  test "should get annotations with limit and offset" do
    s = create_project_source
    c1 = create_comment annotated: s, text: '1'
    c2 = create_comment annotated: s, text: '2'
    c3 = create_comment annotated: create_project_source, text: '3'
    c4 = create_comment annotated: s, text: '4'
    assert_equal ['4', '2', '1'], s.annotation_relation.to_a.collect{ |a| a.data[:text] }
    assert_equal ['2'], s.annotation_relation.offset(1).limit(1).collect{ |a| a.data[:text] }
  end

  test "should not load if does not exist" do
    create_comment
    c = Annotation.all.last
    assert_equal c, c.load
    c.disable_es_callbacks = true
    c.destroy
    assert_nil c.load
  end

  test "should get annotations by type" do
    c = create_comment annotated: nil
    t = create_tag
    s = create_project_source
    s.add_annotation c
    s.add_annotation t
    assert_equal [c], s.annotations('comment')
    assert_equal [t], s.annotations('tag')
  end

  test "should annotate project source" do
    s = create_project_source
    c = create_comment annotated: s
    assert_equal s, c.source
  end

  test "should be an annotation" do
    s = create_source
    assert !s.is_annotation?
    c = create_comment
    assert c.is_annotation?
  end

  test "should get annotation team" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    mc = create_comment annotated: nil
    pm = create_project_media project: p, media: m
    pm.add_annotation mc
    assert_equal mc.get_team, [t.id]
    c = create_comment annotated: nil
    assert_empty c.get_team
  end

  test "should have number of annotations" do
    s = create_project_source
    3.times{ create_comment(annotated: s) }
    assert_equal 3, s.annotations_count
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    p  = create_project team: t
    pm = create_project_media
    c = create_comment
    pm.add_annotation c
    with_current_user_and_team(u, t) do
      assert_equal ['read Comment', 'update Comment', 'destroy Comment'], JSON.parse(c.permissions).keys
    end
  end

  test "non members should not read annotations in private team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    m = create_media team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu
    pp = create_project team: pt
    ppm = create_project_media project: pp
    pc = create_comment annotated: ppm

    with_current_user_and_team(u, t) { Comment.find_if_can(c.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Comment.find_if_can(pc.id) }
    end
    with_current_user_and_team(pu, pt) { Comment.find_if_can(pc.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { Comment.find_if_can(pc.id) }
    end
  end

  test "permissions for locked annotations" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'journalist'
    create_team_user team: t, user: u2, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    s = create_status annotated: pm, locked: true, status: 'undetermined'
    c = create_comment annotated: pm, locked: true
    with_current_user_and_team(u, t) do
      assert_raise RuntimeError do
        s.status = 'false'; s.save!
      end
      assert_raise RuntimeError do
        c.text = 'update comment'; c.save!
      end
    end
    with_current_user_and_team(u2, t) do
      s.status = 'false'; s.save!
      s.locked = false; s.save!
    end
    with_current_user_and_team(u, t) do
      s.status = 'verified'; s.save!
    end
  end

  test "should get right number of annotations" do
    f = create_flag
    c = create_comment
    assert_equal 1, Flag.length
    assert_equal 1, Comment.length
  end

  test "should get dbid" do
    c = create_comment
    assert_equal c.id, c.dbid
  end

  test "should get annotations from multiple types" do
    pm = create_project_media
    c = create_comment annotated: pm
    s = create_status annotated: pm, status: 'verified'
    f = create_flag annotated: pm
    assert_equal 2, pm.annotations(['comment', 'flag']).size
  end

  test "should get core type class" do
    c = create_comment
    assert_equal Comment, Annotation.last.annotation_type_class
  end

  test "should get dynamic type class" do
    a = create_dynamic_annotation annotation_type: 'test'
    assert_equal Dynamic, a.annotation_type_class
  end

  test "should get annotator id for migration" do
    c = Comment.new
    assert_nil c.send(:annotator_id_callback, 'test@test.com')
    u = create_user(email: 'test@test.com')
    assert_equal u.id, c.send(:annotator_id_callback, 'test@test.com')
  end

  test "should get annotated id for migration" do
    pm = create_project_media
    mapping = Hash.new
    c = Comment.new
    assert_nil c.send(:annotated_id_callback, 1, mapping)
    mapping[1] = pm.id
    assert_equal pm.id, c.send(:annotated_id_callback, 1, mapping)
  end

  test "should create version when annotation is destroyed" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      assert_difference 'PaperTrail::Version.count' do
        c.destroy
      end
    end
    v = PaperTrail::Version.last
    assert_equal pm.id, v.associated_id
  end

  test "should not add note do archived item" do
    pm = create_project_media archived: false
    assert_nothing_raised do
      create_comment annotated: pm
    end
    pm.archived = true
    pm.save!
    assert_raises ActiveRecord::RecordInvalid do
      create_comment annotated: pm
    end
  end

  test "should reset archive response" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    TeamBot.delete_all
    tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], approved: true
    tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p
    pm.create_all_archive_annotations
    a = pm.get_annotations('pender_archive').last.load
    f = a.get_field('pender_archive_response')
    f.value = '{"foo":"bar"}'
    f.save!
    v = a.reload.get_field('pender_archive_response').reload.value
    assert_not_equal "{}", v
    pm.reset_archive_response(a)
    v = a.reload.get_field('pender_archive_response').reload.value
    assert_equal "{}", v
  end

  test "should skip reset archive response" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    TeamBot.delete_all
    tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], approved: true
    tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p
    pm.create_all_archive_annotations
    a = pm.get_annotations('pender_archive').last.load
    f = a.get_field('pender_archive_response')
    f.value = '{"foo":"bar"}'
    f.save!
    t.set_limits_keep = false
    t.save!
    v = a.reload.get_field('pender_archive_response').reload.value
    pm = ProjectMedia.find(pm.id)
    pm.reset_archive_response(a)
    v = a.reload.get_field('pender_archive_response').reload.value
    assert_equal '{"foo":"bar"}', v
  end

  test "should assign annotation to user" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t, status: 'member'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm
    c.assigned_to_id = u.id
    c.save!
    assert_equal u, c.reload.assigned_to
  end

  test "should not assign annotation to user if user is not a member of the same team as the annotation" do
    u = create_user
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm
    c.assigned_to_id = u.id
    assert_raises ActiveRecord::RecordInvalid do
      c.save!
    end
    assert_nil c.reload.assigned_to
  end

  test "should get annotations assigned to user" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t, status: 'member'
    p = create_project team: t
    pm = create_project_media project: p
    c1 = create_comment annotated: pm
    c2 = create_comment annotated: pm
    c3 = create_comment annotated: pm
    c1.assigned_to_id = u.id; c1.save!
    c2.assigned_to_id = u.id; c2.save!
    assert_equal [c1, c2].sort, Annotation.assigned_to_user(u).sort 
    assert_equal [c1, c2].sort, Annotation.assigned_to_user(u.id).sort
  end

  test "should get project medias assigned to user" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user user: u, team: t, status: 'member'
    create_team_user user: u2, team: t, status: 'member'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    pm3 = create_project_media project: p
    pm4 = create_project_media project: p
    s1 = create_status status: 'verified', annotated: pm1
    s2 = create_status status: 'verified', annotated: pm2
    s3 = create_status status: 'verified', annotated: pm1
    s4 = create_status status: 'verified', annotated: pm4
    c1 = create_comment annotated: pm1
    c2 = create_comment annotated: pm3
    s1.assigned_to_id = u.id; s1.save!
    s2.assigned_to_id = u.id; s2.save!
    s3.assigned_to_id = u.id; s3.save!
    s4.assigned_to_id = u2.id; s4.save!
    c1.assigned_to_id = u.id; c1.save!
    c2.assigned_to_id = u.id; c2.save!
    assert_equal [pm1, pm2, pm3].sort, Annotation.project_media_assigned_to_user(u).sort
  end

  test "should set assignment to nil if zero" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t, status: 'member'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm
    c.assigned_to_id = u.id
    c.save!
    assert_equal u, c.reload.assigned_to
    c.assigned_to_id = 0
    c.save!
    assert_nil c.reload.assigned_to
  end

  test "should save metadata in annotation" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t, status: 'member', role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    u1 = create_user name: 'Foo'
    u2 = create_user name: 'Bar'
    create_team_user user: u1, team: t, status: 'member'
    create_team_user user: u2, team: t, status: 'member'
    tk = create_task annotated: pm, annotator: u
    tk.assigned_to = u1
    tk.save!
    tk = Task.find(tk.id)
    with_current_user_and_team(u, t) do
      tk.assigned_to = u2
      tk.save!
    end
    v = tk.versions.last
    m = JSON.parse(v.meta)
    assert_equal m['assigned_from_name'], 'Foo'
    assert_equal m['assigned_to_name'], 'Bar'
  end

  test "should get project media for annotation" do
    pm = create_project_media
    t = create_task annotated: pm
    t2 = create_task annotated: t
    assert_equal pm, t2.project_media
  end
end
