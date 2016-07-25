require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SampleModel < ActiveRecord::Base
  has_annotations
end

class TagTest < ActiveSupport::TestCase
  def setup
    super
    Tag.delete_index
    Tag.create_index
    sleep 1
  end

  test "should create tag" do
    assert_difference 'Tag.count' do
      create_tag(tag: 'test')
    end
  end

  test "should set type automatically" do
    t = create_tag
    assert_equal 'tag', t.annotation_type
  end

  test "should have tag" do
    assert_no_difference 'Tag.count' do
      create_tag(tag: nil)
      create_tag(tag: '')
    end
  end

  test "should have annotations" do
    s1 = SampleModel.create!
    assert_equal [], s1.annotations
    s2 = SampleModel.create!
    assert_equal [], s2.annotations

    t1a = create_tag
    assert_nil t1a.annotated
    t1b = create_tag
    assert_nil t1b.annotated
    t2a = create_tag
    assert_nil t2a.annotated
    t2b = create_tag
    assert_nil t2b.annotated

    s1.add_annotation t1a
    t1b.annotated = s1
    t1b.save

    s2.add_annotation t2a
    t2b.annotated = s2
    t2b.save

    sleep 1

    assert_equal s1, t1a.annotated
    assert_equal s1, t1b.annotated
    assert_equal [t1a.id, t1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, t2a.annotated
    assert_equal s2, t2b.annotated
    assert_equal [t2a.id, t2b.id].sort, s2.reload.annotations.map(&:id).sort
  end

  test "should create version when tag is created" do
    t = nil
    assert_difference 'PaperTrail::Version.count', 2 do
      t = create_tag(tag: 'test')
    end
    assert_equal 1, t.versions.count
    v = t.versions.last
    assert_equal 'create', v.event
    assert_equal({ 'annotation_type' => ['', 'tag'], 'annotator_type' => ['', 'User'], 'annotator_id' => ['', '1'], 'tag' => ['', 'test' ] }, JSON.parse(v.object_changes))
  end

  test "should create version when tag is updated" do
    t = create_tag(tag: 'foo')
    t.tag = 'bar'
    t.save
    assert_equal 2, t.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({ 'tag' => ['foo', 'bar'] }, JSON.parse(v.object_changes))
  end

  test "should revert" do
    t = create_tag(tag: 'Version 1')
    t.tag = 'Version 2'; t.save
    t.tag = 'Version 3'; t.save
    t.tag = 'Version 4'; t.save
    assert_equal 4, t.versions.size

    t.revert
    assert_equal 'Version 3', t.tag
    t = t.reload
    assert_equal 'Version 4', t.tag

    t.revert_and_save
    assert_equal 'Version 3', t.tag
    t = t.reload
    assert_equal 'Version 3', t.tag

    t.revert
    assert_equal 'Version 2', t.tag
    t.revert
    assert_equal 'Version 1', t.tag
    t.revert
    assert_equal 'Version 1', t.tag

    t.revert(-1)
    assert_equal 'Version 2', t.tag
    t.revert(-1)
    assert_equal 'Version 3', t.tag
    t.revert(-1)
    assert_equal 'Version 4', t.tag
    t.revert(-1)
    assert_equal 'Version 4', t.tag

    t = t.reload
    assert_equal 'Version 3', t.tag
    t.revert_and_save(-1)
    t = t.reload
    assert_equal 'Version 4', t.tag

    assert_equal 4, t.versions.size
  end

  test "should return whether it has an attribute" do
    t = create_tag
    assert t.has_attribute?(:tag)
  end

  test "should have a single annotation type" do
    t = create_tag
    assert_equal 'annotation', t._type
  end

  test "should have context" do
    t = create_tag
    s = SampleModel.create
    assert_nil t.context
    t.context = s
    t.save
    assert_equal s, t.context
  end

   test "should get annotations from context" do
    context1 = SampleModel.create
    context2 = SampleModel.create
    annotated = SampleModel.create

    t1 = create_tag
    t1.context = context1
    t1.annotated = annotated
    t1.save

    t2 = create_tag
    t2.context = context2
    t2.annotated = annotated
    t2.save

    sleep 1

    assert_equal [t1.id, t2.id].sort, annotated.annotations.map(&:id).sort
    assert_equal [t1.id], annotated.annotations(context1).map(&:id)
    assert_equal [t2.id], annotated.annotations(context2).map(&:id)
  end

  test "should get columns as array" do
    assert_kind_of Array, Tag.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, Tag.columns_hash
  end

  test "should not be abstract" do
    assert_not Tag.abstract_class?
  end

  test "should have content" do
    t = create_tag
    assert_equal ['tag'], JSON.parse(t.content).keys
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = SampleModel.create!
    s2 = SampleModel.create!
    t1 = create_tag annotator: u1, annotated: s1
    t2 = create_tag annotator: u1, annotated: s1
    t3 = create_tag annotator: u1, annotated: s1
    t4 = create_tag annotator: u2, annotated: s1
    t5 = create_tag annotator: u2, annotated: s1
    t6 = create_tag annotator: u3, annotated: s2
    t7 = create_tag annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators
    assert_equal [u3].sort, s2.annotators
  end

end
