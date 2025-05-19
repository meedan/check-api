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
    s = create_project_media
    t1 = create_task annotated: s, label: '1'
    t2 = create_task annotated: s, label: '2'
    t3 = create_task annotated: create_project_media, label: '3'
    t4 = create_task annotated: s, label: '4'
    assert_equal ['4', '2', '1'], s.annotation_relation.to_a.collect{ |a| a.data[:label] }
    assert_equal ['2'], s.annotation_relation.offset(1).limit(1).collect{ |a| a.data[:label] }
  end

  test "should not load if does not exist" do
    create_task
    t = Annotation.all.last
    assert_equal t, t.load
    t.disable_es_callbacks = true
    t.destroy
    assert_nil t.load
  end

  test "should get annotations by type" do
    d = create_dynamic_annotation annotated: nil
    t = create_tag
    s = create_project_media
    s.add_annotation d
    s.add_annotation t
    assert_equal [d], s.annotations('dynamic')
    assert_equal [t], s.annotations('tag')
  end

  test "should be an annotation" do
    s = create_source
    assert !s.is_annotation?
    t = create_task
    assert t.is_annotation?
  end

  test "should get annotation team" do
    t = create_team
    m = create_valid_media
    m1 = create_metadata annotated: nil
    pm = create_project_media team: t, media: m
    pm.add_annotation m1
    assert_equal m1.team, t
    m2 = create_metadata annotated: nil
    assert_nil m2.team
  end

  test "should have number of annotations" do
    s = create_project_media
    3.times{ create_tag(annotated: s) }
    assert_equal 3, s.annotations_count
  end

  test "should get child annotations" do
    m = create_metadata annotated: nil
    m2 = create_metadata annotated: m
    assert_equal [m2], m.annotations
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    pm = create_project_media team: t
    task = create_task
    pm.add_annotation task
    with_current_user_and_team(u, t) do
      assert_equal ['read Task', 'update Task', 'destroy Task'], JSON.parse(task.permissions).keys
    end
  end

  test "non members should not read annotations in private team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    m = create_media team: t
    pm = create_project_media team: t
    tag = create_tag annotated: pm
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu
    ppm = create_project_media team: pt
    tag2 = create_tag annotated: ppm

    with_current_user_and_team(u, t) { Tag.find_if_can(tag.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Tag.find_if_can(tag2.id) }
    end
    with_current_user_and_team(pu, pt) { Tag.find_if_can(tag2.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { Tag.find_if_can(tag2.id) }
    end
  end

  test "permissions for locked annotations" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'collaborator'
    create_team_user team: t, user: u2, role: 'editor'
    pm = create_project_media team: t
    s = create_status annotated: pm, locked: true, status: 'undetermined'
    tag = create_tag annotated: pm, locked: true
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        s.status = 'false'; s.save!
      end
      assert_nothing_raised do
        tag.tag = 'update tag'; tag.save!
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
    t = create_task
    assert_equal 1, Dynamic.where(annotation_type: 'flag').count
    assert_equal 1, Task.length
  end

  test "should get dbid" do
    t = create_task
    assert_equal t.id, t.dbid
  end

  test "should get annotations from multiple types" do
    pm = create_project_media
    t = create_task annotated: pm
    s = create_status annotated: pm, status: 'verified'
    f = create_flag annotated: pm
    assert_equal 2, pm.annotations(['task', 'flag']).size
  end

  test "should get core type class" do
    t = create_task
    assert_equal Task, Annotation.last.annotation_type_class
  end

  test "should get dynamic type class" do
    a = create_dynamic_annotation annotation_type: 'test'
    assert_equal Dynamic, a.annotation_type_class
  end

  test "should get annotator id for migration" do
    t = Tag.new
    assert_nil t.send(:annotator_id_callback, 'test@test.com')
    u = create_user(email: 'test@test.com')
    assert_equal u.id, t.send(:annotator_id_callback, 'test@test.com')
  end

  test "should get annotated id for migration" do
    pm = create_project_media
    mapping = Hash.new
    t = Tag.new
    assert_nil t.send(:annotated_id_callback, 1, mapping)
    mapping[1] = pm.id
    assert_equal pm.id, t.send(:annotated_id_callback, 1, mapping)
  end

  test "should create version when annotation is destroyed" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user user: u, team: t
      pm = create_project_media team: t
      tag = create_tag annotated: pm, annotator: u
      with_current_user_and_team(u, t) do
        assert_difference 'PaperTrail::Version.count' do
          tag.destroy
        end
      end
      v = PaperTrail::Version.last
      assert_equal pm.id, v.associated_id
    end
  end

  test "should reset archive response" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t
    pm.create_all_archive_annotations
    a = pm.get_annotations('archiver').last.load
    f = a.get_field('pender_archive_response')
    f.value = '{"foo":"bar"}'
    f.save!
    v = a.reload.get_field('pender_archive_response').reload.value
    assert_not_equal "{}", v
    pm.reset_archive_response(a, 'pender_archive')
    v = a.reload.get_field('pender_archive_response').reload.value
    assert_equal "{}", v
  end

  test "should skip reset archive response" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t
    pm.create_all_archive_annotations
    a = pm.get_annotations('archiver').last.load
    f = a.get_field('pender_archive_response')
    f.value = '{"foo":"bar"}'
    f.save!
    User.current = nil
    tbi.set_archive_pender_archive_enabled = false
    tbi.save!
    v = a.reload.get_field('pender_archive_response').reload.value
    pm = ProjectMedia.find(pm.id)
    pm.reset_archive_response(a, 'pender_archive')
    v = a.reload.get_field('pender_archive_response').reload.value
    assert_equal '{"foo":"bar"}', v
  end

  test "should assign annotation to user" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t, status: 'member'
    pm = create_project_media team: t
    task = create_task annotated: pm
    u.assign_annotation(task)
    assert_equal [u], task.reload.assigned_users
  end

  test "should not assign annotation to user if user is not a member of the same team as the annotation" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    task = create_task annotated: pm
    assert_raises ActiveRecord::RecordInvalid do
      task.assign_user(u.id)
    end
    assert_equal [], task.reload.assignments
  end

  test "should get annotations assigned to user" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t, status: 'member'
    pm = create_project_media team: t
    task1 = create_task annotated: pm
    task2 = create_task annotated: pm
    task3 = create_task annotated: pm
    task1.assign_user(u.id)
    task2.assign_user(u.id)
    assert_equal [task1, task2].sort, Annotation.assigned_to_user(u).sort
    assert_equal [task1, task2].sort, Annotation.assigned_to_user(u.id).sort
  end

  # TODO: Review by Sawy
  # test "should get project medias assigned to user" do
  #   u = create_user
  #   u2 = create_user
  #   t = create_team
  #   create_team_user user: u, team: t, status: 'member'
  #   create_team_user user: u2, team: t, status: 'member'
  #   pm1 = create_project_media team: t
  #   pm2 = create_project_media team: t
  #   pm3 = create_project_media team: t
  #   pm4 = create_project_media team: t
  #   pm5 = create_project_media team: t
  #   pm6 = create_project_media team: t
  #   s1 = create_status status: 'verified', annotated: pm1
  #   s2 = create_status status: 'verified', annotated: pm2
  #   s3 = create_status status: 'verified', annotated: pm1
  #   s4 = create_status status: 'verified', annotated: pm4
  #   task1 = create_task annotated: pm1
  #   task2 = create_task annotated: pm3
  #   s1.assign_user(u.id)
  #   s2.assign_user(u.id)
  #   s3.assign_user(u.id)
  #   s4.assign_user(u2.id)
  #   task1.assign_user(u.id)
  #   task2.assign_user(u.id)
  #   # Assignment.create! assigned: p2, user: u
  #   assert_equal [pm1, pm2, pm3, pm5, pm6].sort, Annotation.project_media_assigned_to_user(u, 'id').sort
  # end

  test "should save metadata in annotation" do
    with_versioning do
      u = create_user
      t = create_team
      tu = create_team_user user: u, team: t, status: 'member', role: 'admin'
      pm = create_project_media team: t
      u1 = create_user name: 'Foo'
      u2 = create_user name: 'Bar'
      create_team_user user: u1, team: t, status: 'member'
      create_team_user user: u2, team: t, status: 'member'
      tk = create_task annotated: pm, annotator: u
      tk = Task.find(tk.id)
      with_current_user_and_team(u, t) do
        tk.assign_user(u1.id)
        tk.assign_user(u2.id)
      end
      v = tk.assignments.first.versions.last
      m = JSON.parse(v.meta)
      assert_equal m['user_name'], 'Foo'
      v = tk.assignments.last.versions.last
      m = JSON.parse(v.meta)
      assert_equal m['user_name'], 'Bar'
    end
  end

  test "should get project media for annotation" do
    pm = create_project_media
    t = create_task annotated: pm
    t2 = create_task annotated: t
    assert_equal pm, t2.project_media
  end

  test "should assign and unassign users" do
    t = create_team
    pm = create_project_media team: t
    task = create_task annotated: pm
    u1 = create_user
    u2 = create_user
    u3 = create_user
    u4 = create_user
    [u1, u2, u3, u4].each{ |u| create_team_user(user: u, team: t) }
    assert_difference 'Assignment.count', 2 do
      task.assigned_to_ids = [u1.id, u2.id].join(',')
      task.save!
    end
    assert_equal [u1, u2].sort, task.assigned_users.sort
    assert_no_difference 'Assignment.count' do
      task.assigned_to_ids = [u3.id, u4.id].join(',')
      task.save!
    end
    assert_equal [u3, u4].sort, task.assigned_users.sort
    assert_difference 'Assignment.count', -1 do
      task.assigned_to_ids = [u3.id].join(',')
      task.save!
    end
    assert_equal [u3], task.assigned_users
    assert_difference 'Assignment.count', 3 do
      task.assigned_to_ids = [u1.id, u2.id, u3.id, u4.id].join(',')
      task.save!
    end
    assert_equal [u1, u2, u3, u4].sort, task.assigned_users.sort
    assert_difference 'Assignment.count', -1 do
      u1.destroy
    end
    assert_difference 'Assignment.count', -3 do
      task.reload.destroy
    end
  end

  test "should get assignment team" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    pm = create_project_media team: t
    task = create_task annotated: pm
    task.assign_user(u.id)
    assert_equal t, task.assignments.last.team
  end

  test "should not propagate assignments when generic annotations are assigned" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    pm = create_project_media team: t
    a = create_tag annotated: pm
    assert_difference 'Assignment.count', 1 do
      a.assign_user(u.id)
    end
  end

  test "should not notify Pusher depending on annotation type" do
    create_annotation_type_and_fields('Slack Message', { 'Data' => ['JSON', false] })
    assert_nothing_raised do
      Pusher::Client.any_instance.unstub(:trigger)
      Pusher::Client.any_instance.unstub(:post)
      a = create_dynamic_annotation annotation_type: 'slack_message', set_fields: { slack_message_data: { value: random_string(10001) }.to_json }.to_json
      Pusher::Client.any_instance.stubs(:trigger)
      Pusher::Client.any_instance.stubs(:post)
      assert !a.sent_to_pusher
    end
  end

  test "should save annotation with null byte" do
    assert_difference "Task.where(annotation_type: 'task').count" do
      create_task label: "*Dipa's Crush Loves him 97�\u0000, How Much Your Crush Loves You?* Check out now\nhttps://www.getlinks.info/love/c/tnxbmka"
    end
  end

  test "should parse media fragments" do
    require 'uri'

    # Extend URI module by adding a "media_fragment" method to URI objects
    uri = URI.parse('http://www.example.com/example.ogv#t=10,20')
    assert_equal({ 't' => [10.0, 20.0] }, uri.media_fragment)

    # Parse fragments in annotations
    a = Annotation.new(fragment: 't=10,20')
    assert_equal({ 't' => [10.0, 20.0] }, a.parsed_fragment)

    # Now test the parser itself with different cases
    assert_equal({}, URI.media_fragment('t=foo:10'))
    assert_equal({}, URI.media_fragment('t=foo'))
    assert_equal({}, URI.media_fragment('foo=bar'))
    assert_equal({ 't' => [10.0] }, URI.media_fragment('t=10&bar=foo'))
    assert_equal({ 't' => [0.0, 10.0] }, URI.media_fragment('t=,10'))
    assert_equal({ 't' => [10.0] }, URI.media_fragment('t=10'))
    assert_equal({ 't' => [10.0, 20.0] }, URI.media_fragment('t=10,20'))
    assert_equal({ 't' => [0.0, 10.0] }, URI.media_fragment('t=npt:,10'))
    assert_equal({ 't' => [10.0] }, URI.media_fragment('t=npt:10'))
    assert_equal({ 't' => [10.0, 20.0] }, URI.media_fragment('t=npt:10,20'))
    assert_equal({ 't' => [10.3, 20.54] }, URI.media_fragment('t=10.3,20.54'))
    assert_equal({ 't' => [120.1, 121.5] }, URI.media_fragment('t=120.1,0:02:01.5'))
    assert_equal({ 't' => [18610.0, 18620.0] }, URI.media_fragment('t=05:10:10,05:10:20'))
    assert_equal({}, URI.media_fragment('xywh=foo'))
    assert_equal({}, URI.media_fragment('xywh=pixel:1,2,3'))
    assert_equal({}, URI.media_fragment('xywh=foo:1,2,3,4'))
    assert_equal({}, URI.media_fragment('xywh=foo:1,2,3,4.5'))
    assert_equal({ 'xywh' => { 'x' => 1, 'y' => 2, 'width' => 3, 'height' => 4, 'unit' => 'pixel' } }, URI.media_fragment('xywh=pixel:1,2,3,4'))
    assert_equal({ 'xywh' => { 'x' => 1, 'y' => 2, 'width' => 3, 'height' => 4, 'unit' => 'pixel' } }, URI.media_fragment('xywh=1,2,3,4'))
    assert_equal({ 'xywh' => { 'x' => 1, 'y' => 2, 'width' => 3, 'height' => 4, 'unit' => 'percent' } }, URI.media_fragment('xywh=percent:1,2,3,4'))
    assert_equal({ 'xywh' => { 'x' => 160, 'y' => 120, 'width' => 320, 'height' => 240, 'unit' => 'pixel' } }, URI.media_fragment('xywh=160,120,320,240'))
    assert_equal({ 't' => [10.0, 20.0], 'xywh' => { 'x' => 160, 'y' => 120, 'width' => 320, 'height' => 240, 'unit' => 'pixel' } }, URI.media_fragment('xywh=160,120,320,240&t=10,20'))
  end

  test "should get parsed fragment" do
    a = Annotation.new(fragment: nil)
    assert_equal({}, a.parsed_fragment)
    a = Annotation.new(fragment: 't=10,20')
    assert_equal({ 't' => [10.0, 20.0] }, a.parsed_fragment)
    a = Annotation.new(fragment: '["t=10,20","t=30,40"]')
    assert_equal([{ 't' => [10.0, 20.0] }, { 't' => [30.0, 40.0] }], a.parsed_fragment)
    a = Annotation.new(fragment: '%5B%22t%3D10%2C20%22%2C%20%22t%3D30%2C40%22%5D')
    assert_equal([{ 't' => [10.0, 20.0] }, { 't' => [30.0, 40.0] }], a.parsed_fragment)
  end
end
