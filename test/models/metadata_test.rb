require_relative '../test_helper'

class MetadataTest < ActiveSupport::TestCase
  test "should create metadata" do
    pm = create_project_media
    u = create_user
    assert_difference "Annotation.where(annotation_type: 'metadata').count" do
      create_metadata(annotated: pm, annotator: u)
    end
  end

  test "should set type automatically" do
    em = create_metadata
    assert_equal 'metadata', em.annotation_type
  end

  test "should have annotations" do
    s1 = create_project_media
    assert_equal [], s1.annotations
    s2 = create_project_media
    assert_equal [], s2.annotations

    em1a = create_metadata annotated: nil
    assert_nil em1a.annotated
    em1b = create_metadata annotated: nil
    assert_nil em1b.annotated
    em2a = create_metadata annotated: nil
    assert_nil em2a.annotated
    em2b = create_metadata annotated: nil
    assert_nil em2b.annotated

    s1.add_annotation em1a
    em1b.annotated = s1
    em1b.save

    s2.add_annotation em2a
    em2b.annotated = s2
    em2b.save

    assert_equal s1, em1a.annotated
    assert_equal s1, em1b.annotated
    assert_equal [em1a.id, em1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, em2a.annotated
    assert_equal s2, em2b.annotated
    assert_equal [em2a.id, em2b.id].sort, s2.reload.annotations.map(&:id).sort
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
    s1 = create_project_media
    s2 = create_project_media
    em1 = create_metadata annotator: u1, annotated: s1
    em2 = create_metadata annotator: u1, annotated: s1
    em3 = create_metadata annotator: u1, annotated: s1
    em4 = create_metadata annotator: u2, annotated: s1
    em5 = create_metadata annotator: u2, annotated: s1
    em6 = create_metadata annotator: u3, annotated: s2
    em7 = create_metadata annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators.sort
    assert_equal [u3].sort, s2.annotators.sort
  end

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'admin'
    with_current_user_and_team(u2, t) do
      em = create_metadata annotated: t, annotator: nil
      assert_equal u2, em.reload.annotator
    end
  end

  test "should protect attributes from mass assignment" do
    raw_params = { annotation_type: 'metadata', annotated: create_project_media }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Dynamic.create(params)
    end
  end

  test "should not send Slack notification for metadata that is not related to project media" do
    l = create_link
    em = create_metadata annotated: l
    Dynamic.any_instance.stubs(:title_is_overridden?).returns(true)
    Dynamic.any_instance.stubs(:overridden_data).returns([{'title' => 'Test'}])
    User.stubs(:current).returns(create_user)
    assert_nothing_raised do
      em.slack_notification_message
    end
    Dynamic.any_instance.unstub(:title_is_overridden?)
    Dynamic.any_instance.unstub(:overridden_data)
    User.unstub(:current)
  end

  test "should get and set fields" do
    require File.join(Rails.root, 'app', 'models', 'annotations', 'embed')
    m = create_metadata
    
    m = Dynamic.find(m.id)
    m.title = 'Foo'
    m.save!
    
    m = Dynamic.find(m.id)
    m.description = 'Bar'
    m.save!
    
    m = Dynamic.find(m.id)
    assert_equal 'Foo', m.title
    assert_equal 'Bar', m.description
  end
end
