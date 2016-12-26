require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AnnotationTest < ActiveSupport::TestCase
  test "should not create generic annotation" do
    assert_no_difference 'Annotation.count' do
      assert_raises RuntimeError do
        create_annotation annotation_type: nil
      end
    end
  end

  test "should have empty content by default" do
    assert_equal '{}', Annotation.new.content
  end

  test "should get annotations with limit and offset" do
    s = create_project_source
    c1 = create_comment annotated: s, text: '1'
    c2 = create_comment annotated: s, text: '2'
    c3 = create_comment annotated: create_project_source, text: '3'
    c4 = create_comment annotated: s, text: '4'
    assert_equal ['4', '2', '1'], s.annotation_relation.to_a.collect{ |a| a.data[:text] }
    assert_equal ['2'], s.annotation_relation.offset(1).limit(1).collect{ |a| a.data[:text] }
  end

  test "should not load if does not exist" do
    create_comment
    c = Annotation.all.last
    assert_equal c, c.load
    c.destroy
    assert_nil c.load
  end

  test "should get annotations by type" do
    c = create_comment annotated: nil
    t = create_tag annotated: nil
    s = create_project_source
    s.add_annotation c
    s.add_annotation t
    assert_equal [c], s.annotations('comment')
    assert_equal [t], s.annotations('tag')
  end

  test "should annotate project source" do
    s = create_project_source
    c = create_comment annotated: s
    assert_equal s, c.source
  end

  test "should be an annotation" do
    s = create_source
    assert !s.is_annotation?
    c = create_comment
    assert c.is_annotation?
  end

  test "should get annotation team" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    mc = create_comment annotated: nil
    pm = create_project_media project: p, media: m
    pm.add_annotation mc
    assert_equal mc.get_team, [t.id]
    c = create_comment annotated: nil
    assert_empty c.get_team
  end

  test "should have number of annotations" do
    s = create_project_source
    3.times{ create_comment(annotated: s) }
    assert_equal 3, s.annotations_count
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    p  = create_project team: t
    pm = create_project_media
    c = create_comment
    pm.add_annotation c
    c.current_user = u
    assert_equal ['read Comment', 'update Comment', 'destroy Comment'], JSON.parse(c.permissions).keys
  end

  test "non members should not read annotations in private team" do
    u = create_user
    t = create_team current_user: create_user
    p = create_project team: t
    m = create_media team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm
    pu = create_user
    pt = create_team current_user: pu, private: true
    pp = create_project team: pt
    ppm = create_project_media project: pp
    pc = create_comment annotated: ppm
    Comment.find_if_can(c.id, u, t)
    assert_raise CheckdeskPermissions::AccessDenied do
      Comment.find_if_can(pc.id, u, pt)
    end
    Comment.find_if_can(pc.id, pu, pt)
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      Comment.find_if_can(pc.id, pu, pt)
    end
  end

  test "should get right number of annotations" do
    f = create_flag
    c = create_comment
    assert_equal 1, Flag.length
    assert_equal 1, Comment.length
  end

  test "should get dbid" do
    c = create_comment
    assert_equal c.id, c.dbid
  end

  test "should get annotations from multiple types" do
    pm = create_project_media
    c = create_comment annotated: pm
    s = create_status annotated: pm
    f = create_flag annotated: pm
    assert_equal 2, pm.annotations(['comment', 'flag']).size
  end
end
