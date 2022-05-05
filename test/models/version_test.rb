require_relative '../test_helper'

class VersionTest < ActiveSupport::TestCase
  test "should have item" do
    v = create_version
    assert_kind_of ProjectMedia, v.item
  end

  test "should have annotation" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    tg = create_tag annotated: pm
    User.current = nil
    v = tg.versions.last
    assert_equal tg, v.annotation.load
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
    create_team_user user: u, team: t, role: 'admin'
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    tg = create_tag annotated: pm, tag: 'Foo', annotator: u
    tg.tag = 'Bar'
    tg.save!
    User.current = nil
    assert_equal tg.tag, JSON.parse(tg.versions.last.object_after)['data']['tag']
  end

  test "should set user" do
    u = create_user
    User.current = u
    v = create_version(user: u)
    User.current = nil
    assert_not_nil v.whodunnit
  end

  test "should get changes as JSON" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    tg = create_tag annotated: pm, tag: 'Foo', annotator: u
    tag_a = tg.reload.tag
    tg.tag = 'Bar'
    tg.save!
    tag_b = tg.reload.tag
    assert_equal "{\"data\":[{\"tag\":#{tag_a}},{\"tag\":#{tag_b}}]}", tg.reload.versions.last.object_changes_json
  end

  test "should set event type" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    u = User.find(u.id)
    p = create_project team: t
    pm = create_project_media project: p
    User.current = u
    tg = create_tag annotated: pm, tag: 'Foo', annotator: u
    tg = Tag.last
    tg.tag = 'Bar'
    tg.save!
    User.current = nil
    assert_equal 'update_tag', tg.reload.versions.last.event_type
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
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      pm = create_project_media team: t
      v = pm.versions.last
      v.destroy!
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
    v = create_version
    assert_not_nil v.project_media
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

  # TODO: fix by Sawy
  # test "should get smooch user slack channel url" do
  #   b = create_team_bot login: 'smooch', set_approved: true
  #   create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
  #   create_annotation_type_and_fields('Smooch User', {
  #     'Data' => ['JSON', false],
  #     'Slack Channel Url' => ['Text', true],
  #     'ID' => ['Text', false]
  #   })
  #   u = create_user
  #   t = create_team
  #   create_team_user team: t, user: u, role: 'admin'
  #   pm = create_project_media team: t
  #   author_id = random_string
  #   url = random_url
  #   set_fields = { smooch_user_id: author_id, smooch_user_data: { id: author_id }.to_json, smooch_user_slack_channel_url: url }.to_json
  #   d = create_dynamic_annotation annotated: t, annotation_type: 'smooch_user', set_fields: set_fields
  #   tb = create_team_bot_installation team_id: t.id, user_id: b.id
  #   with_current_user_and_team(u, t) do
  #     ds = create_dynamic_annotation annotation_type: 'smooch', annotated: pm, set_fields: { smooch_data: { 'authorId' => author_id }.to_json }.to_json
  #     f = ds.get_field('smooch_data')
  #     v = f.versions.last
  #     assert_equal url, v.smooch_user_slack_channel_url
  #     assert 1, Rails.cache.delete_matched("SmoochUserSlackChannelUrl:Team:*")
  #     assert_equal url, v.smooch_user_slack_channel_url
  #   end
  # end

  test "should return version from action" do
    ActiveRecord::Base.shared_connection = ApplicationRecord.connection # Use the same database connection for all threads
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

      # Concurrency
      10.times do
        threads = []
        @v1 = nil
        @v2 = nil
        @tag = tag
        threads << Thread.start do
          User.current = create_user(is_admin: true)
          tag1 = Tag.find(@tag.id)
          tag1.tag = random_string
          tag1.save_with_version!
          @v1 = tag1.version_object
        end
        threads << Thread.start do
          User.current = create_user(is_admin: true)
          tag2 = Tag.find(@tag.id)
          tag2.tag = random_string
          tag2.save_with_version!
          @v2 = tag2.version_object
        end
        threads.map(&:join)
        assert_not_equal @v1.id, @v2.id
      end
    end
  end
end
