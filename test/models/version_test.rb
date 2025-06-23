require_relative '../test_helper'

class VersionTest < ActiveSupport::TestCase
  test "should have item" do
    v = create_version
    assert_kind_of ProjectMedia, v.item
  end

  test "should have annotation" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user user: u, team: t
      u = User.find(u.id)
      pm = create_project_media team: t
      User.current = u
      tg = create_tag annotated: pm
      User.current = nil
      v = tg.versions.last
      assert_equal tg, v.annotation.load
      assert_nil create_version.annotation
    end
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
    with_versioning do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      u = User.find(u.id)
      pm = create_project_media team: t
      User.current = u
      tg = create_tag annotated: pm, tag: 'Foo', annotator: u
      tg.tag = 'Bar'
      tg.save!
      User.current = nil
      assert_equal tg.tag, JSON.parse(tg.versions.last.object_after)['data']['tag']
    end
  end

  test "should set user" do
    u = create_user
    User.current = u
    v = create_version(user: u)
    User.current = nil
    assert_not_nil v.whodunnit
  end

  test "should get task" do
    with_versioning do
      Version.delete_all
      v = create_version
      assert_nil v.task
      at = create_annotation_type annotation_type: 'task_response'
      ft2 = create_field_type field_type: 'text'
      create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
      create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'note'
      t = create_task
      u = create_user is_admin: true
      User.current = u
      t = Task.find(t.id)
      t.response = { annotation_type: 'task_response', set_fields: { response: 'Test', note: 'Test' }.to_json }.to_json
      t.save!
      Version.from_partition(t.team&.id).where(item_type: 'DynamicAnnotation::Field').each do |version|
        assert_equal(t, version.task) if version.item.annotation.annotation_type =~ /response/
      end
      User.current = nil
    end
  end

  test "should get changes as JSON" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      u = User.find(u.id)
      pm = create_project_media team: t
      User.current = u
      tg = create_tag annotated: pm, tag: 'Foo', annotator: u
      tag_a = tg.reload.tag
      tg.tag = 'Bar'
      tg.save!
      tag_b = tg.reload.tag
      assert_equal "{\"data\":[{\"tag\":#{tag_a}},{\"tag\":#{tag_b}}]}", tg.reload.versions.last.object_changes_json
    end
  end

  test "should set event type" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      u = User.find(u.id)
      pm = create_project_media team: t
      User.current = u
      tg = create_tag annotated: pm, tag: 'Foo', annotator: u
      tg = Tag.last
      tg.tag = 'Bar'
      tg.save!
      User.current = nil
      assert_equal 'update_tag', tg.reload.versions.last.event_type
    end
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


  test "should destroy version" do
    with_versioning do
      u = create_user is_admin: true
      t = create_team
      create_team_user team: t, user: u, role: 'admin'
      with_current_user_and_team(u, t) do
        pm = create_project_media team: t
        v = pm.versions.last
        v.destroy!
      end
    end
  end

  test "should get source" do
    v = create_version
    assert_not_nil v.source
  end

  test "should get associated GraphQL ID" do
    v = create_version
    assert_kind_of String, v.associated_graphql_id
  end

  test "should get project media" do
    with_versioning do
      v = create_version
      assert_not_nil v.project_media
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      with_current_user_and_team(u, t) do
        pm = create_project_media team: t
        tg = create_tag annotated: pm
        v = tg.versions.last
        assert_not_nil v.project_media
      end
    end
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

  test "should return version from action" do
    with_versioning do
      u = create_user is_admin: true
      t = create_team
      create_team_user user: u, team: t
      pm = create_project_media team: t
      with_current_user_and_team(u, t) do
        tag = nil
        assert_difference 'Version.count' do
          tag = Tag.new annotated: pm, annotator: u, tag: random_string
          tag.save_with_version!
        end
        v = tag.version_object
        assert_equal 'create_tag', v.event_type
        tag = Tag.find(tag.id)
        assert_nil tag.version_object
        tag.tag = random_string
        assert_difference 'Version.count' do
          tag.save_with_version!
        end
        v = tag.version_object
        assert_equal 'update_tag', v.event_type
      end
    end
  end

  test "should sanitize content before bulk-importing" do
    t = create_team
    versions = [{
      item_type: 'Team',
      item_id: t.id,
      event: 'update',
      whodunnit: nil,
      object: t.to_json,
      object_changes: {
        updated_at: [t.updated_at, Time.now],
        settings: { description: "DK Shivakumar was seen drunk in today’s 'Mekedatu" }.to_yaml,
      }.to_json,
      created_at: Time.now,
      meta: {}.to_json,
      event_type: 'update_team',
      object_after: t.to_json,
      associated_id: t.id,
      associated_type: 'Team',
      team_id: t.id
    }]
    assert_nothing_raised do
      assert_difference "Version.from_partition(#{t.id}).count" do
        Team.bulk_import_versions(versions, t.id)
      end
    end
  end
end
