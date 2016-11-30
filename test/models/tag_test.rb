require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SampleModel < ActiveRecord::Base
  has_annotations
end

class TagTest < ActiveSupport::TestCase
  test "should create tag" do
    assert_difference 'Tag.length' do
      create_tag(tag: 'test')
    end
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    m = create_valid_media project_id: p.id, user: u
    assert_difference 'Tag.length' do
      create_tag tag: 'media_tag', context: p, annotated: m, current_user: u, context_team: t, annotator: u
    end
  end

  test "should set type automatically" do
    t = create_tag
    assert_equal 'tag', t.annotation_type
  end

  test "should have tag" do
    assert_no_difference 'Tag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tag(tag: nil)
        create_tag(tag: '')
      end
    end
  end

  test "should have annotations" do
    s1 = SampleModel.create!
    assert_equal [], s1.annotations
    s2 = SampleModel.create!
    assert_equal [], s2.annotations

    t1a = create_tag annotated: nil
    assert_nil t1a.annotated
    t1b = create_tag annotated: nil
    assert_nil t1b.annotated
    t2a = create_tag annotated: nil
    assert_nil t2a.annotated
    t2b = create_tag annotated: nil
    assert_nil t2b.annotated

    s1.add_annotation t1a
    t1b.annotated = s1
    t1b.save

    s2.add_annotation t2a
    t2b.annotated = s2
    t2b.save

    assert_equal s1, t1a.annotated
    assert_equal s1, t1b.annotated
    assert_equal [t1a.id, t1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, t2a.annotated
    assert_equal s2, t2b.annotated
    assert_equal [t2a.id, t2b.id].sort, s2.reload.annotations.map(&:id).sort
  end

  test "should create version when tag is created" do
    t = nil
    assert_difference 'PaperTrail::Version.count', 3 do
      t = create_tag(tag: 'test')
    end
    assert_equal 1, t.versions.count
    v = t.versions.last
    assert_equal 'create', v.event
    assert_equal({"data"=>["{}", "{\"tag\"=>\"test\", \"full_tag\"=>\"test\"}"], "annotator_type"=>["", "User"], "annotator_id"=>["", "#{t.annotator_id}"], "annotated_type"=>["", "Source"], "annotated_id"=>["", "#{t.annotated_id}"], "annotation_type"=>["", "tag"]}, JSON.parse(v.object_changes))
  end

  test "should create version when tag is updated" do
    create_tag(tag: 'foo')
    t = Tag.last
    t.tag = 'bar'
    t.save
    assert_equal 2, t.versions.count
    v = PaperTrail::Version.last
    assert_equal 'update', v.event
    assert_equal({"data"=>["{\"tag\"=>\"foo\", \"full_tag\"=>\"foo\"}", "{\"tag\"=>\"bar\", \"full_tag\"=>\"bar\"}"]}, JSON.parse(v.object_changes))
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

    assert_equal [t1.id, t2.id].sort, annotated.annotations.map(&:id).sort
    assert_equal [t1.id], annotated.annotations(nil, context1).map(&:id)
    assert_equal [t2.id], annotated.annotations(nil, context2).map(&:id)
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
    assert_equal [u1, u2].sort, s1.annotators.sort
    assert_equal [u3].sort, s2.annotators.sort
  end

  test "should get annotator" do
    t = create_tag
    assert_nil t.send(:annotator_callback, 'test@test.com')
    u = create_user(email: 'test@test.com')
    assert_equal u, t.send(:annotator_callback, 'test@test.com')
  end

  test "should get target id" do
    t = create_tag
    assert_equal 2, t.target_id_callback(1, [1, 2, 3])
  end

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2
    m = create_valid_media team: t, current_user: u2
    t = create_tag annotated: m, annotator: nil, current_user: u2
    assert_equal u2, t.annotator
  end

  test "should set not annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2
    m = create_valid_media team: t, current_user: u2
    t = create_tag annotated: m, annotator: u1, current_user: u2
    assert_equal u1, t.annotator
  end

  test "should not have same tag applied to same object" do
    s1 = create_source
    s2 = create_source
    p = create_project
    assert_difference 'Tag.length', 4 do
      assert_nothing_raised do
        create_tag tag: 'foo', annotated: s1, context: p
        create_tag tag: 'foo', annotated: s2, context: p
        create_tag tag: 'bar', annotated: s1, context: p
        create_tag tag: 'bar', annotated: s2, context: p
      end
    end
    assert_no_difference 'Tag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tag tag: 'foo', annotated: s1, context: p
        create_tag tag: 'foo', annotated: s2, context: p
        create_tag tag: 'bar', annotated: s1, context: p
        create_tag tag: 'bar', annotated: s2, context: p
      end
    end
  end

  test "should not tell that one tag contained in another is a duplicate" do
    s = create_source
    p = create_project
    assert_difference 'Tag.length', 2 do
      assert_nothing_raised do
        create_tag tag: 'foo bar', annotated: s, context: p
        create_tag tag: 'foo', annotated: s, context: p
      end
    end
    assert_no_difference 'Tag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tag tag: 'foo', annotated: s, context: p
      end
    end
  end

  test "should create elasticsearch tag" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    t = create_tag annotated: m, context: p, tag: 'sports'
    sleep 1
    result = TagSearch.find(t.id, parent: pm.id)
    assert_equal t.id.to_s, result.id
  end

  test "should update elasticsearch tag" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    t = create_tag annotated: m, context: p, tag: 'sports'
    t.tag = 'sports-news'; t.save!
    sleep 1
    result = TagSearch.find(t.id, parent: pm.id)
    assert_equal 'sports-news', result.tag
  end

end
