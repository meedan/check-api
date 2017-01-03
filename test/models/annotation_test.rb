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
    s = create_source
    c1 = create_comment annotated: s, text: '1'
    c2 = create_comment annotated: s, text: '2'
    c3 = create_comment annotated: create_source, text: '3'
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
    c = create_comment
    t = create_tag
    s = create_source
    s.add_annotation c
    s.add_annotation t
    assert_equal [c], s.annotations('comment')
    assert_equal [t], s.annotations('tag')
  end

  test "should annotate source" do
    s = create_source
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
    pc = create_comment
    mc = create_comment
    p.add_annotation pc
    pm = create_project_media project: p, media: m
    m.add_annotation mc
    assert_equal pc.get_team, [t.id]
    assert_equal mc.get_team, [t.id]
    c = create_comment
    assert_empty c.get_team
  end

  test "should have number of annotations" do
    s = create_source
    3.times{ create_comment(annotated: s) }
    assert_equal 3, s.annotations_count
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    p  = create_project team: t
    pc = create_comment
    p.add_annotation pc
    with_current_user_and_team(u, t) do
      assert_equal ['read Comment', 'update Comment', 'destroy Comment'], JSON.parse(pc.permissions).keys
    end
  end

  test "non members should not read annotations in private team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    m = create_media team: t
    c = create_comment
    m.add_annotation c
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu
    pm = create_media team: pt
    pc = create_comment
    pm.add_annotation pc
    with_current_user_and_team(u, t) { Comment.find_if_can(c.id) }
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Comment.find_if_can(pc.id) }
    end
    with_current_user_and_team(pu, pt) { Comment.find_if_can(pc.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { Comment.find_if_can(pc.id) }
    end
  end

  test "should get right number of annotations" do
    f = create_flag
    c = create_comment
    assert_equal 1, Flag.length
    assert_equal 1, Comment.length
  end

  test "should get annotations from any context, no context or some context" do
    m = create_valid_media
    p1 = create_project
    p2 = create_project
    c1 = create_comment context: p1, annotated: m
    c2 = create_comment context: p2, annotated: m
    c3 = create_comment context_id: nil, context_type: nil, context: nil, annotated: m
    f = create_flag context: p1, annotated: m
    assert_equal [c1], m.annotations('comment', p1)
    assert_equal [c2], m.annotations('comment', p2)
    assert_includes m.annotations('comment'), c1
    assert_includes m.annotations('comment'), c2
    assert_includes m.annotations('comment'), c3
    assert_equal [c3], m.annotations('comment', 'none')
    assert_includes m.annotations('comment', 'some'), c1
    assert_includes m.annotations('comment', 'some'), c2
    refute_includes m.annotations('comment', 'some'), c3
  end

  test "should get dbid" do
    c = create_comment
    assert_equal c.id, c.dbid
  end

  test "should get annotations from multiple types" do
    m = create_valid_media
    c = create_comment annotated: m
    s = create_status annotated: m, status: 'verified'
    f = create_flag annotated: m, flag: 'Spam'
    assert_equal 2, m.annotations(['comment', 'status']).size
  end
end
