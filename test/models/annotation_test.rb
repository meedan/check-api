require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CommentTest < ActiveSupport::TestCase
  def setup
    super
    Annotation.delete_index
    Annotation.create_index
    sleep 1
  end

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
    assert_equal ['4', '2', '1'], s.annotation_relation.to_a.map(&:text)
    assert_equal ['2'], s.annotation_relation.offset(1).limit(1).all.map(&:text)
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
    sleep 1
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
    assert_equal pc.get_team, t.id
    assert_equal mc.get_team, t.id
    c = create_comment
    assert_nil c.get_team
  end

end
