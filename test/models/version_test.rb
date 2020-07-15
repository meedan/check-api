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
    Version.from_partition(t.team&.id).where(item_type: 'DynamicAnnotation::Field').each do |version|
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

  test "should get teams" do
    u = create_user is_admin: true
    t = create_team
    t2 = create_team
    User.current = u
    pm = create_project_media team: t
    pm.team = t2
    pm.save!
    log = pm.get_versions_log(['update_projectmedia']).last
    assert_equal [t, t2], log.get_from_object_changes(:team)
    User.current = nil
  end

  test "should get projects" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    p2 = create_project team: t
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p
      pmp = pm.project_media_projects.last
      assert_not_nil pmp
      pmp.project_id = p2.id
      pmp.save!
      log = pm.get_versions_log(['update_projectmediaproject']).last
      assert_equal [p, p2], log.projects
    end
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
    v.associated_type = 'FooBar'
    v.associated_id = random_number
    assert_nil v.associated
  end

  test "should get smooch user slack channel url" do
    b = create_team_bot login: 'smooch', set_approved: true
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    create_annotation_type_and_fields('Smooch User', {
      'Data' => ['JSON', false],
      'Slack Channel Url' => ['Text', true]
    })
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    author_id = random_string
    url = random_url
    set_fields = { smooch_user_data: { id: author_id }.to_json, smooch_user_slack_channel_url: url }.to_json
    d = create_dynamic_annotation annotated: p, annotation_type: 'smooch_user', set_fields: set_fields
    tb = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_project_id: p.id }
    with_current_user_and_team(u, t) do
      ds = create_dynamic_annotation annotation_type: 'smooch', annotated: pm, set_fields: { smooch_data: { 'authorId' => author_id }.to_json }.to_json
      f = ds.get_field('smooch_data')
      v = f.versions.last
      assert_equal url, v.smooch_user_slack_channel_url
      assert 1, Rails.cache.delete_matched("SmoochUserSlackChannelUrl:Team:*")
      assert_equal url, v.smooch_user_slack_channel_url
    end
  end
end
