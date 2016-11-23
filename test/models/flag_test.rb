require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class FlagTest < ActiveSupport::TestCase
  test "should create flag" do
    assert_difference 'Flag.length' do
      create_flag
    end
  end

  test "should set type automatically" do
    f = create_flag
    assert_equal 'flag', f.annotation_type
  end

  test "should have flag" do
    assert_no_difference 'Flag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_flag(flag: nil)
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_flag(flag: '')
      end
    end
  end

  test "should create version when flag is created" do
    f = nil
    assert_difference 'PaperTrail::Version.count', 2 do
      f = create_flag(flag: 'Spam', annotated: nil)
    end
    assert_equal 1, f.versions.count
    v = f.versions.last
    assert_equal 'create', v.event
    assert_equal({"data"=>["", "{\"flag\"=>\"Spam\"}"], "annotator_type"=>["", "User"], "annotator_id"=>["", "#{f.annotator_id}"], "annotation_type"=>["", "flag"]}, JSON.parse(v.object_changes))
  end

  test "should create version when flag is updated" do
    f = create_flag(flag: 'Spam')
    f = Flag.last
    f.flag = 'Graphic content'
    f.save
    assert_equal 2, f.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({"data"=>["{\"flag\"=>\"Spam\"}", "{\"flag\"=>\"Graphic content\"}"]}, JSON.parse(v.object_changes))
  end

  test "should have context" do
    f = create_flag
    s = create_project
    assert_nil f.context
    f.context = s
    f.save
    assert_equal s, f.context
  end

   test "should get annotations from context" do
    context1 = create_project
    context2 = create_project
    annotated = create_valid_media

    f1 = create_flag
    f1.context = context1
    f1.annotated = annotated
    f1.save

    f2 = create_flag
    f2.context = context2
    f2.annotated = annotated
    f2.save

    sleep 1

    assert_equal [f1.id, f2.id].sort, annotated.annotations('flag').map(&:id).sort
    assert_equal [f1.id], annotated.annotations(nil, context1).map(&:id)
    assert_equal [f2.id], annotated.annotations(nil, context2).map(&:id)
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
    f = create_flag
    assert_equal ['flag'], JSON.parse(f.content).keys
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_valid_media
    s2 = create_valid_media
    f1 = create_flag annotator: u1, annotated: s1
    f2 = create_flag annotator: u1, annotated: s1
    f3 = create_flag annotator: u1, annotated: s1
    f4 = create_flag annotator: u2, annotated: s1
    f5 = create_flag annotator: u2, annotated: s1
    f6 = create_flag annotator: u3, annotated: s2
    f7 = create_flag annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators.sort
    assert_equal [u3].sort, s2.annotators.sort
  end

  test "should get annotator" do
    f = create_flag
    assert_nil f.send(:annotator_callback, 'test@tef.com')
    u = create_user(email: 'test@tef.com')
    assert_equal u, f.send(:annotator_callback, 'test@tef.com')
  end

  test "should get target id" do
    f = create_flag
    assert_equal 2, f.target_id_callback(1, [1, 2, 3])
  end

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'contributor'
    m = create_valid_media team: t, current_user: u2
    f = create_flag annotated: m, annotator: nil, current_user: u2
    assert_equal u2, f.annotator
  end

  test "should set not annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'contributor'
    m = create_valid_media team: t, current_user: u2
    f = create_flag annotated: m, annotator: u1, current_user: u2
    assert_equal u1, f.annotator
  end

  test "should not create flag with invalid value" do
    assert_no_difference 'Flag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_flag flag: 'invalid'
      end
    end
    assert_difference 'Flag.length' do
      create_flag flag: 'Spam'
    end
  end

  test "should not create flag with invalid annotated" do
    assert_no_difference 'Flag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_flag annotated: create_source
      end
    end
  end

 test "should get flag" do
    f = create_flag
    assert_equal 'Graphic content', f.flag_callback('graphic_journalist')
    assert_equal 'Invalid', f.flag_callback('Invalid')
  end

end
