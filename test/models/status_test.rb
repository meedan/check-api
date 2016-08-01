require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SampleModel < ActiveRecord::Base
  has_annotations
end

class StatusTest < ActiveSupport::TestCase
  def setup
    super
    Status.delete_index
    Status.create_index
    sleep 1
  end

  test "should create status" do
    assert_difference 'Status.count' do
      create_status
    end
  end

  test "should set type automatically" do
    st = create_status
    assert_equal 'status', st.annotation_type
  end

  test "should have status" do
    assert_no_difference 'Status.count' do
      create_status(status: nil)
      create_status(status: '')
    end
  end

  test "should have annotations" do
    s1 = SampleModel.create!
    assert_equal [], s1.annotations
    s2 = SampleModel.create!
    assert_equal [], s2.annotations

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

    sleep 1

    assert_equal s1, t1a.annotated
    assert_equal s1, t1b.annotated
    assert_equal [t1a.id, t1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, t2a.annotated
    assert_equal s2, t2b.annotated
    assert_equal [t2a.id, t2b.id].sort, s2.reload.annotations.map(&:id).sort
  end

  test "should create version when status is created" do
    st = nil
    assert_difference 'PaperTrail::Version.count', 3 do
      st = create_status(status: 'Credible')
    end
    assert_equal 1, st.versions.count
    v = st.versions.last
    assert_equal 'create', v.event
    assert_equal({ 'annotation_type' => ['', 'status'], 'annotated_type' => ['', 'Source'], 'annotated_id' => ['', st.annotated_id], 'annotator_type' => ['', 'User'], 'annotator_id' => ['', st.annotator_id], 'status' => ['', 'Credible' ] }, JSON.parse(v.object_changes))
  end

  test "should create version when status is updated" do
    st = create_status(status: 'Slightly Credible')
    st.status = 'Sockpuppet'
    st.save
    assert_equal 2, st.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({ 'status' => ['Slightly Credible', 'Sockpuppet'] }, JSON.parse(v.object_changes))
  end

  test "should revert" do
    st = create_status(status: 'Credible')
    st.status = 'Not Credible'; st.save
    st.status = 'Slightly Credible'; st.save
    st.status = 'Sockpuppet'; st.save
    assert_equal 4, st.versions.size

    st.revert
    assert_equal 'Slightly Credible', st.status
    st = st.reload
    assert_equal 'Sockpuppet', st.status

    st.revert_and_save
    assert_equal 'Slightly Credible', st.status
    st = st.reload
    assert_equal 'Slightly Credible', st.status

    st.revert
    assert_equal 'Not Credible', st.status
    st.revert
    assert_equal 'Credible', st.status
    st.revert
    assert_equal 'Credible', st.status

    st.revert(-1)
    assert_equal 'Not Credible', st.status
    st.revert(-1)
    assert_equal 'Slightly Credible', st.status
    st.revert(-1)
    assert_equal 'Sockpuppet', st.status
    st.revert(-1)
    assert_equal 'Sockpuppet', st.status

    st = st.reload
    assert_equal 'Slightly Credible', st.status
    st.revert_and_save(-1)
    st = st.reload
    assert_equal 'Sockpuppet', st.status

    assert_equal 4, st.versions.size
  end

  test "should return whether it has an attribute" do
    st = create_status
    assert st.has_attribute?(:status)
  end

  test "should have a single annotation type" do
    st = create_status
    assert_equal 'annotation', st._type
  end

  test "should have context" do
    st = create_status
    s = SampleModel.create
    assert_nil st.context
    st.context = s
    st.save
    assert_equal s, st.context
  end

   test "should get annotations from context" do
    context1 = SampleModel.create
    context2 = SampleModel.create
    annotated = SampleModel.create

    st1 = create_status
    st1.context = context1
    st1.annotated = annotated
    st1.save

    st2 = create_status
    st2.context = context2
    st2.annotated = annotated
    st2.save

    sleep 1

    assert_equal [st1.id, st2.id].sort, annotated.annotations.map(&:id).sort
    assert_equal [st1.id], annotated.annotations(nil, context1).map(&:id)
    assert_equal [st2.id], annotated.annotations(nil, context2).map(&:id)
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
    s1 = SampleModel.create!
    s2 = SampleModel.create!
    st1 = create_status annotator: u1, annotated: s1
    st2 = create_status annotator: u1, annotated: s1
    st3 = create_status annotator: u1, annotated: s1
    st4 = create_status annotator: u2, annotated: s1
    st5 = create_status annotator: u2, annotated: s1
    st6 = create_status annotator: u3, annotated: s2
    st7 = create_status annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators
    assert_equal [u3].sort, s2.annotators
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
    u1 = create_user
    u2 = create_user
    st = create_status annotator: nil, current_user: u2
    assert_equal u2, st.annotator
  end

  test "should set not annotator if set" do
    u1 = create_user
    u2 = create_user
    st = create_status annotator: u1, current_user: u2
    assert_equal u1, st.annotator
  end

  test "should not create status with invalid value" do
    assert_no_difference 'Status.count' do
      create_status status: 'invalid', annotated: create_valid_media
    end
    assert_no_difference 'Status.count' do
      create_status status: 'invalid'
    end
    assert_difference 'Status.count' do
      create_status status: 'Credible'
    end
    assert_difference 'Status.count' do
      create_status status: 'Verified', annotated: create_valid_media
    end
  end

  test "should not create status with invalid annotated" do
    assert_no_difference 'Status.count' do
      create_status status: 'Verified', annotated: create_project
    end
  end

end
