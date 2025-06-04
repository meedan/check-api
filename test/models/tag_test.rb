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
    create_team_user team: t, user: u, role: 'collaborator'
    pm = create_project_media team: t, user: u
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
    s1 = create_project_media
    assert_equal [], s1.annotations
    s2 = create_project_media
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
    with_versioning do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      pm = create_project_media team: t
      with_current_user_and_team(u, t) do
        tag = create_tag(tag: 'test', annotated: pm)
        assert_equal 1, tag.versions.count
        v = tag.versions.last
        assert_equal 'create', v.event
      end
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
    s1 = create_project_media
    s2 = create_project_media
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
    create_team_user team: t, user: u
    pm = create_project_media team: t, user: u
    with_current_user_and_team(u, t) do
      t = create_tag annotated: pm, annotator: nil
      assert_equal u, t.annotator
    end
  end

  test "should not set annotator if set" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2
    pm = create_project_media team: t, user: u2

    with_current_user_and_team(u2, t) do
      t = create_tag annotated: pm, annotator: u
      assert_equal u, t.annotator
    end
  end

  test "should not have same tag applied to same object" do
    s1 = create_project_media
    s2 = create_project_media
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
    s = create_project_media
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

  test "should not get tag text reference if tag is already a number" do
    t = create_team
    pm = create_project_media team: t
    tt = create_tag_text text: 'test', team_id: t.id
    ta = nil
    assert_no_difference 'TagText.count' do
      ta = create_tag(tag: tt.id, annotated: pm)
    end
    assert_equal 'test', ta.tag_text
  end

  test "should get tag text reference if tag is a string" do
    t = create_team
    pm = create_project_media team: t
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
    assert_difference 'TagText.count' do
      5.times { create_tag(tag: 'test', annotated: create_project_media(team: t)) }
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

  test "should get team" do
    t = create_tag
    assert_kind_of Team, t.team
  end

  test "should not crash if tag to be updated does not exist" do
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    tt1 = create_tag_text team_id: t.id
    tt2 = create_tag_text team_id: t.id
    t1 = create_tag tag: tt1.id, annotated: pm1
    t2 = create_tag tag: tt1.id, annotated: pm2
    tt2.delete
    TagText.update_tags(tt1.id, t.id, tt2.id)
  end

  test "should treat ' tag' and 'tag' as the same tag, and not try to create a new tag" do
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t

    create_tag tag: 'foo', annotated: pm1

    assert_nothing_raised do
      create_tag tag: ' foo', annotated: pm2
    end
  end

  test ":create_project_media_tags should create tags when project media id and tags are present" do
    team = create_team
    pm = create_project_media team: team
    project_media_id = pm.id
    tags_json = ['one', 'two'].to_json
    assert_nothing_raised do
      Tag.create_project_media_tags(project_media_id, tags_json)
    end
    assert_equal 2, pm.annotations('tag').count
  end

  test ":create_project_media_tags should not raise an error when no project media is sent" do
    project_media_id = nil
    tags_json = ['one', 'two'].to_json

    assert_nothing_raised do
      CheckSentry.expects(:notify).once
      Tag.create_project_media_tags(project_media_id, tags_json)
    end
  end

  test ":create_project_media_tags should not try to create duplicate tags" do
    Sidekiq::Testing.fake!
    team = create_team
    pm = create_project_media team: team
    Tag.create_project_media_tags(pm.id, ['one', 'one', '#one'].to_json)
    tags = pm.reload.annotations('tag')
    tag_text_id = tags.last.data['tag']
    tag_text = TagText.find(tag_text_id).text

    assert_equal 1, tags.count
    assert_equal 'one', tag_text
  end

  test ":create_project_media_tags should be able to add an existing tag to a new project media" do
    Sidekiq::Testing.fake!
    team = create_team
    pm = create_project_media team: team
    Tag.create_project_media_tags(pm.id, ['one'].to_json)
    pm2 = create_project_media team: team
    Tag.create_project_media_tags(pm2.id, ['#one'].to_json)

    assert_equal 1, pm2.reload.annotations('tag').count
  end

  test ":create_project_media_tags should be able to ignore tag already added to item" do
    Sidekiq::Testing.fake!

    team = create_team
    pm = create_project_media team: team
    create_tag tag: 'two', annotated: pm
    assert_equal 1, pm.reload.annotations('tag').count

    Tag.create_project_media_tags(pm.id, ['one', 'two', 'three'].to_json)
    assert_equal 3, pm.reload.annotations('tag').count
  end

  test "all_sorted returns tags sorted by created_at" do
    t1 = create_tag(tag: 'a')
    t1.update_columns(created_at: 2.days.ago)
    t2 = create_tag(tag: 'b')
    t2.update_columns(created_at: 1.day.ago)

    sorted_asc = Tag.all_sorted('asc', 'created_at')
    assert_operator sorted_asc.first.created_at, :<, sorted_asc.last.created_at

    sorted_desc = Tag.all_sorted('desc', 'created_at')
    assert_operator sorted_desc.first.created_at, :>, sorted_desc.last.created_at
  end

  test "current_team returns the team when annotated is ProjectMedia" do
    u = create_user
    team = create_team
    pm = create_project_media team: team, user: u
    
    tag = create_tag(annotated: pm)
    tag.annotated_type = 'ProjectMedia'
    tag.save
    
    assert_equal team, tag.current_team
  end
end
