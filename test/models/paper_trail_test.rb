require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class PaperTrailTest < ActiveSupport::TestCase
  test "should have item" do
    v = create_version
    assert_kind_of Team, v.item
  end

  test "should have annotation" do
    c = create_comment
    v = c.versions.last
    assert_equal c, v.annotation.load
    assert_nil create_version.annotation
  end

  test "should have user" do
    v = create_version
    u = create_user
    assert_nil v.user
    v.whodunnit = u.id.to_s
    v.save!
    assert_equal u, v.reload.user
  end

  test "should get object" do
    v = create_version
    assert_kind_of Hash, v.get_object
  end

  test "should apply changes" do
    c = create_comment text: 'Foo'
    c.text = 'Bar'
    c.save!
    assert_equal 'Bar', JSON.parse(c.versions.last.object_after)['data']['text']
  end

  test "should set user" do
    u = create_user
    User.current = u
    v = create_version
    assert_equal u, v.reload.user
    User.current = nil
  end

  test "should get projects" do
    v = create_version
    p1 = create_project
    p2 = create_project
    assert_equal [], v.projects
    pm = create_project_media project: p1
    pm = ProjectMedia.find(pm.id)
    pm.project_id = p2.id
    pm.save!
    assert_equal [p1, p2], pm.versions.last.projects
  end

  test "should get task" do
    PaperTrail::Version.delete_all
    v = create_version
    assert_nil v.task
    at = create_annotation_type annotation_type: 'response'
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'note'
    t = create_task
    t = Task.find(t.id); t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s, note: 'Test' }.to_json }.to_json; t.save!
    PaperTrail::Version.where(item_type: 'DynamicAnnotation::Field').each do |version|
      assert_equal(t, version.task) if version.item.annotation.annotation_type =~ /^task_response/
    end
  end

  test "should get changes as JSON" do
    create_comment text: 'Foo'
    c = Comment.last
    c.text = 'Bar'
    c.save!
    assert_equal "{\"data\":[{\"text\":\"Foo\"},{\"text\":\"Bar\"}]}", c.reload.versions.last.object_changes_json
  end

  test "should set event type" do
    create_comment text: 'Foo'
    c = Comment.last
    c.text = 'Bar'
    c.save!
    assert_equal 'update_comment', c.reload.versions.last.event_type
  end
end
