require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SampleModel < ActiveRecord::Base
  has_annotations
end

class EmbedTest < ActiveSupport::TestCase
  test "should create embed" do
    assert_difference 'Embed.length' do
      create_embed(embed: 'test')
    end
  end

  test "should set type automatically" do
    em = create_embed
    assert_equal 'embed', em.annotation_type
  end

  test "should have quote if media url is blank" do
    assert_no_difference 'Embed.length' do
      m = Media.new
      m.save!
      assert_raise RuntimeError do
        em = Embed.new
        em.annotated = m
        em.quote = ''
        em.save!
      end
    end
  end

  test "should have annotations" do
    s1 = SampleModel.create!
    assert_equal [], s1.annotations
    s2 = SampleModel.create!
    assert_equal [], s2.annotations

    em1a = create_embed annotated: nil
    assert_nil em1a.annotated
    em1b = create_embed annotated: nil
    assert_nil em1b.annotated
    em2a = create_embed annotated: nil
    assert_nil em2a.annotated
    em2b = create_embed annotated: nil
    assert_nil em2b.annotated

    s1.add_annotation em1a
    em1b.annotated = s1
    em1b.save

    s2.add_annotation em2a
    em2b.annotated = s2
    em2b.save

    sleep 1

    assert_equal s1, em1a.annotated
    assert_equal s1, em1b.annotated
    assert_equal [em1a.id, em1b.id].sort, s1.reload.annotations.map(&:id).sort

    assert_equal s2, em2a.annotated
    assert_equal s2, em2b.annotated
    assert_equal [em2a.id, em2b.id].sort, s2.reload.annotations.map(&:id).sort
  end

  test "should return whether it has an attribute" do
    em = create_embed
    assert em.has_attribute?(:embed)
  end

  test "should have a single annotation type" do
    em = create_embed
    assert_equal 'annotation', em._type
  end

  test "should have context" do
    em = create_embed
    s = SampleModel.create
    assert_nil em.context
    em.context = s
    em.save
    assert_equal s, em.context
  end

  test "should get annotations from context" do
    context1 = SampleModel.create
    context2 = SampleModel.create
    annotated = SampleModel.create

    em1 = create_embed
    em1.context = context1
    em1.annotated = annotated
    em1.save

    em2 = create_embed
    em2.context = context2
    em2.annotated = annotated
    em2.save

    sleep 1

    assert_equal [em1.id, em2.id].sort, annotated.annotations.map(&:id).sort
    assert_equal [em1.id], annotated.annotations(nil, context1).map(&:id)
    assert_equal [em2.id], annotated.annotations(nil, context2).map(&:id)
  end

  test "should get columns as array" do
    assert_kind_of Array, Embed.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, Embed.columns_hash
  end

  test "should not be abstract" do
    assert_not Embed.abstract_class?
  end

  test "should have content" do
    em = create_embed
    assert_equal ["title", "description", "username", "published_at", "quote", "embed"].sort, JSON.parse(em.content).keys.sort
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = SampleModel.create!
    s2 = SampleModel.create!
    em1 = create_embed annotator: u1, annotated: s1
    em2 = create_embed annotator: u1, annotated: s1
    em3 = create_embed annotator: u1, annotated: s1
    em4 = create_embed annotator: u2, annotated: s1
    em5 = create_embed annotator: u2, annotated: s1
    em6 = create_embed annotator: u3, annotated: s2
    em7 = create_embed annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators
    assert_equal [u3].sort, s2.annotators
  end

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'owner'
    p = create_project team: t, current_user: u2
    em = create_embed annotated: p, annotator: nil, current_user: u2
    assert_equal u2, em.annotator
  end

end
