require_relative '../test_helper'

class TagTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    TagText.delete_all
  end

  test "should create tag" do
    assert_difference 'Tag.length' do
      create_tag(tag: 'test')
    end
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p, user: u
    assert_difference 'Tag.length' do
      with_current_user_and_team(u, t) do
        create_tag tag: 'media_tag', annotated: pm, annotator: u
      end
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
    s1 = create_project_source
    assert_equal [], s1.annotations
    s2 = create_project_source
    assert_equal [], s2.annotations

    t1a = create_tag
    t1b = create_tag
    t2a = create_tag
    t2b = create_tag

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
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tag = create_tag(tag: 'test', annotated: pm)
      assert_equal 1, tag.versions.count
      v = tag.versions.last
      assert_equal 'create', v.event
    end
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
    tt = create_tag_text text: 'test'
    t = create_tag tag: tt.id
    content = JSON.parse(t.content)
    assert_equal ['tag', 'tag_text_id'].sort, content.keys.sort
    assert_equal tt.id, content['tag_text_id']
    assert_equal 'test', content['tag']
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_project_source
    s2 = create_project_source
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

  test "should set annotator if not set" do
    u = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u
    pm = create_project_media project: p, user: u
    with_current_user_and_team(u, t) do
      t = create_tag annotated: pm, annotator: nil
      assert_equal u, t.annotator
    end
  end

  test "should not set annotator if set" do
    u = create_user
    u2 = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u2
    pm = create_project_media project: p, user: u2

    with_current_user_and_team(u2, t) do
      t = create_tag annotated: pm, annotator: u
      assert_equal u, t.annotator
    end
  end

  test "should not have same tag applied to same object" do
    s1 = create_project_source
    s2 = create_project_source
    p = create_project
    assert_difference 'Tag.length', 8 do
      assert_nothing_raised do
        create_tag tag: 'foo', annotated: s1
        create_tag tag: 'foo', annotated: s2
        create_tag tag: 'bar', annotated: s1
        create_tag tag: 'bar', annotated: s2
        create_tag tag: 'foo', annotated: s1, fragment: 't=1'
        create_tag tag: 'foo', annotated: s2, fragment: 't=2'
        create_tag tag: 'bar', annotated: s1, fragment: 't=3'
        create_tag tag: 'bar', annotated: s2, fragment: 't=4'
      end
    end
    assert_no_difference 'Tag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tag tag: 'foo', annotated: s1
        create_tag tag: 'foo', annotated: s2
        create_tag tag: 'bar', annotated: s1
        create_tag tag: 'bar', annotated: s2
      end
    end
  end

  test "should not tell that one tag contained in another is a duplicate" do
    s = create_project_source
    assert_difference 'Tag.length', 2 do
      assert_nothing_raised do
        create_tag tag: 'foo bar', annotated: s
        create_tag tag: 'foo', annotated: s
      end
    end
    assert_no_difference 'Tag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tag tag: 'foo', annotated: s
      end
    end
  end

  test "should protect attributes from mass assignment" do
    raw_params = { annotator: create_user, tag: 'my tag' }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Tag.create(params)
    end
  end

  test "should return project source" do
    pm = create_project_media
    ps = create_project_source
    t1 = create_tag annotated: pm
    t2 = create_tag annotated: ps
    assert_nil t1.project_source
    assert_equal ps, t2.project_source
  end

  test "should not get tag text reference if tag is already a number" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tt = create_tag_text text: 'test', team_id: t.id
    ta = nil
    assert_no_difference 'TagText.count' do
      ta = create_tag(tag: tt.id, annotated: pm)
    end
    assert_equal 'test', ta.tag_text
  end

  test "should get tag text reference if tag is a string" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tt = create_tag_text text: 'test', team_id: t.id
    ta = nil
    assert_no_difference 'TagText.count' do
      ta = create_tag(tag: 'test', annotated: pm)
    end
    assert_equal 'test', ta.tag_text
  end

  test "should create tag text reference if tag is a string" do
    t = nil
    assert_difference 'TagText.count' do
      t = create_tag tag: 'test'
    end
    assert_equal 'test', t.tag_text
  end

  test "should exist only one tag text for duplicated tags of the same team" do
    t = create_team
    p = create_project team: t 
    assert_difference 'TagText.count' do
      5.times { create_tag(tag: 'test', annotated: create_project_media(project: p)) }
    end
  end

  test "should validate that tag text exists" do
    assert_raises ActiveRecord::RecordInvalid do
      create_tag tag: 0
    end
  end

  test "should get tag text object" do
    tt = create_tag_text
    t = create_tag tag: tt.id
    assert_equal tt, t.tag_text_object
  end

  test "should get tag text" do
    tt = create_tag_text text: 'test'
    t = create_tag tag: tt.id
    assert_equal 'test', t.tag_text
  end

  test "should delete tag text if last tag is deleted" do
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    tt = create_tag_text team_id: t.id
    t1 = create_tag tag: tt.id, annotated: pm1
    t2 = create_tag tag: tt.id, annotated: pm2
    assert_no_difference 'TagText.count' do
      t1.destroy
    end
    assert_difference 'TagText.count', -1 do
      t2.destroy
    end
  end

  test "should not delete tag text if last tag is deleted but tag text is teamwide" do
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    tt = create_tag_text team_id: t.id, teamwide: true
    t1 = create_tag tag: tt.id, annotated: pm1
    t2 = create_tag tag: tt.id, annotated: pm2
    assert_no_difference 'TagText.count' do
      t1.destroy
    end
    assert_no_difference 'TagText.count' do
      t2.destroy
    end
  end

  test "should get team" do
    t = create_tag
    assert_kind_of Team, t.team
  end

  test "should not crash if tag to be updated does not exist" do
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    tt1 = create_tag_text team_id: t.id, teamwide: true
    tt2 = create_tag_text team_id: t.id, teamwide: true
    t1 = create_tag tag: tt1.id, annotated: pm1
    t2 = create_tag tag: tt1.id, annotated: pm2
    tt2.delete
    TagText.update_tags(tt1.id, t.id, tt2.id)
  end
end
