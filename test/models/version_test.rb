require_relative '../test_helper'

class VersionTest < ActiveSupport::TestCase
  test "should have item" do
    v = create_version
    assert_kind_of Team, v.item
  end

  test "should have annotation" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    c = create_comment annotated: pm
    User.current = nil
    v = c.versions.last
    assert_equal c, v.annotation.load
    assert_nil create_version.annotation
  end

  test "should have user" do
    v = create_version
    u = create_user
    assert_not_equal u, v.reload.user
    v.whodunnit = u.id.to_s
    v.save!
    assert_equal u, v.reload.user
  end

  test "should get object" do
    v = create_version
    assert_kind_of Hash, v.get_object
  end

  test "should apply changes" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    c = create_comment annotated: pm, text: 'Foo', annotator: u
    c.text = 'Bar'
    c.save!
    User.current = nil
    assert_equal 'Bar', JSON.parse(c.versions.last.object_after)['data']['text']
  end

  test "should set user" do
    u = create_user
    User.current = u
    v = create_version(user: u)
    User.current = nil
    assert_not_nil v.whodunnit
  end

  test "should get projects" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    v = create_version
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    assert_equal [], v.projects
    m = create_valid_media
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p1, media: m, user: u
      pm = ProjectMedia.find(pm.id)
      pm.project_id = p2.id
      pm.save!
      assert_equal [p1, p2], pm.versions.last.projects
    end
  end

  test "should get task" do
    Version.delete_all
    v = create_version
    assert_nil v.task
    at = create_annotation_type annotation_type: 'response'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'note'
    t = create_task
    u = create_user is_admin: true
    User.current = u
    t = Task.find(t.id); t.response = { annotation_type: 'response', set_fields: { response: 'Test', note: 'Test' }.to_json }.to_json; t.save!
    Version.from_partition(t.team_id).where(item_type: 'DynamicAnnotation::Field').each do |version|
      assert_equal(t, version.task) if version.item.annotation.annotation_type =~ /response/
    end
    User.current = nil
  end

  test "should get changes as JSON" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    c = create_comment annotated: pm, text: 'Foo', annotator: u
    c = Comment.last
    c.text = 'Bar'
    c.save!
    assert_equal "{\"data\":[{\"text\":\"Foo\"},{\"text\":\"Bar\"}]}", c.reload.versions.last.object_changes_json
  end

  test "should set event type" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    c = create_comment annotated: pm, text: 'Foo', annotator: u
    c = Comment.last
    c.text = 'Bar'
    c.save!
    User.current = nil
    assert_equal 'update_comment', c.reload.versions.last.event_type
  end

  test "should skip ability" do
    v = create_version
    assert v.skip_check_ability
  end

  test "should not raise error when deserialize and change is a hash" do
    pt = Version.new
    data1 = [nil, "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nlabel: Who is who?\ntype: free_text\nrequired: false\ndescription: ''\nstatus: unresolved\nslug: who_is_who\n"]
    data2 = [{}, {"text"=>"In a separate news report, Davao City Vice Mayor Paolo Duterte also denied the allegations, calling the witness a \"madman\"."}]
    [data1, data2].each do |data|
      data.each do |d|
        assert_nothing_raised do
          pt.deserialize_change(d)
        end
      end
    end
  end

  test "should return nil item if type is not valid" do
    v = create_version
    v.item_type = 'Test'
    assert_nil v.item
  end

  test "should return dbid" do
    v = create_version
    assert_equal v.id, v.dbid
  end

  test "should get source" do
    v = create_version
    assert_nil v.source
  end

  test "should get associated GraphQL ID" do
    v = create_version
    assert_kind_of String, v.associated_graphql_id
  end

  test "should get project media" do
    v = create_version
    assert_nil v.project_media
  end

  test "should get associated" do
    v = create_version
    pm = create_project_media
    v.associated_type = 'ProjectMedia'
    v.associated_id = pm.id
    assert_equal pm, v.associated
  end
end
