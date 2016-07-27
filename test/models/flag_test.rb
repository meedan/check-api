require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SampleModel < ActiveRecord::Base
  has_annotations
end

class FlagTest < ActiveSupport::TestCase
  def setup
    super
    Flag.delete_index
    Flag.create_index
    sleep 1
  end

  test "should create flag" do
    assert_difference 'Flag.count' do
      create_flag
    end
  end

  test "should set type automatically" do
    f =  create_flag
    assert_equal 'flag', f.annotation_type
  end

  test "should have flag" do
    assert_no_difference 'Flag.count' do
      create_flag(flag: nil)
      create_flag(flag: '')
    end
  end

  test "should create version when flag is created" do
    f =  nil
    assert_difference 'PaperTrail::Version.count', 2 do
      f =  create_flag(flag: 'spam')
    end
    assert_equal 1, f.versions.count
    v = f.versions.last
    assert_equal 'create', v.event
    assert_equal({ 'annotation_type' => ['', 'flag'], 'annotator_type' => ['', 'User'], 'annotator_id' => ['', f.annotator_id], 'flag' => ['', 'spam' ] }, JSON.parse(v.object_changes))
  end

  test "should create version when flag is updated" do
    f =  create_flag(flag: 'spam')
    f.flag = 'graphic content'
    f.save
    assert_equal 2, f.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({ 'flag' => ['spam', 'graphic content'] }, JSON.parse(v.object_changes))
  end

  test "should revert" do
    f =  create_flag(flag: 'spam')
    f.flag = 'graphic content'; f.save
    f.flag = 'fact checking'; f.save
    assert_equal 3, f.versions.size

    f.revert
    assert_equal 'graphic content', f.flag
    f =  f.reload
    assert_equal 'fact checking', f.flag

    f.revert_and_save
    assert_equal 'graphic content', f.flag
    f =  f.reload
    assert_equal 'graphic content', f.flag

    f.revert
    assert_equal 'spam', f.flag
    f.revert
    assert_equal 'spam', f.flag

    f.revert(-1)
    assert_equal 'graphic content', f.flag
    f.revert(-1)
    assert_equal 'fact checking', f.flag
    f.revert(-1)
    assert_equal 'fact checking', f.flag


    f =  f.reload
    assert_equal 'graphic content', f.flag
    f.revert_and_save(-1)
    f =  f.reload
    assert_equal 'fact checking', f.flag

    assert_equal 3, f.versions.size
  end

  test "should return whether it has an attribute" do
    f =  create_flag
    assert f.has_attribute?(:flag)
  end

  test "should have a single annotation type" do
    f =  create_flag
    assert_equal 'annotation', f._type
  end

  test "should have context" do
    f =  create_flag
    s = SampleModel.create
    assert_nil f.context
    f.contexflag = s
    f.save
    assert_equal s, f.context
  end

   test "should get annotations from context" do
    context1 = SampleModel.create
    context2 = SampleModel.create
    annotated = SampleModel.create

    f1 = create_flag
    f1.contexflag = context1
    f1.annotated = annotated
    f1.save

    f2 = create_flag
    f2.contexflag = context2
    f2.annotated = annotated
    f2.save

    sleep 1

    assert_equal [f1.id, f2.id].sort, annotated.annotations.map(&:id).sort
    assert_equal [f1.id], annotated.annotations(context1).map(&:id)
    assert_equal [f2.id], annotated.annotations(context2).map(&:id)
  end

  test "should get columns as array" do
    assert_kind_of Array, Flag.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, Flag.columns_hash
  end

  test "should not be abstract" do
    assert_not Flag.abstract_class?
  end

  test "should have content" do
    f =  create_flag
    assert_equal ['flag'], JSON.parse(f.content).keys
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = SampleModel.create!
    s2 = SampleModel.create!
    f1 = create_flag annotator: u1, annotated: s1
    f2 = create_flag annotator: u1, annotated: s1
    f3 = create_flag annotator: u1, annotated: s1
    f4 = create_flag annotator: u2, annotated: s1
    f5 = create_flag annotator: u2, annotated: s1
    f6 = create_flag annotator: u3, annotated: s2
    f7 = create_flag annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators
    assert_equal [u3].sort, s2.annotators
  end

  test "should get annotator" do
    f =  create_flag
    assert_nil f.send(:annotator_callback, 'test@tef.com')
    u = create_user(email: 'test@tef.com')
    assert_equal u, f.send(:annotator_callback, 'test@tef.com')
  end

  test "should get target id" do
    f =  create_flag
    assert_equal 2, f.target_id_callback(1, [1, 2, 3])
  end

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    f =  create_flag annotator: nil, current_user: u2
    assert_equal u2, f.annotator
  end

  test "should set not annotator if set" do
    u1 = create_user
    u2 = create_user
    f =  create_flag annotator: u1, current_user: u2
    assert_equal u1, f.annotator
  end

end
