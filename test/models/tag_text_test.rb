require_relative '../test_helper'

class TagTextTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    TagText.delete_all
  end

  test "should create" do
    assert_difference 'TagText.count' do
      create_tag_text
    end
  end

  test "should not have two tags with same text and team" do
    assert_nothing_raised do
      assert_difference 'TagText.count' do
        create_tag_text text: 'test'
      end
    end
    t = create_team
    assert_nothing_raised do
      assert_difference 'TagText.count' do
        create_tag_text text: 'test', team_id: t.id
      end
    end
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'TagText.count' do
        create_tag_text text: 'test', team_id: t.id
      end
    end
  end

  test "should not have empty tag" do
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'TagText.count' do
        create_tag_text text: nil
        create_tag_text text: ''
      end
    end
  end

  test "should not have tag without team" do
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'TagText.count' do
        create_tag_text team_id: nil
      end
    end
  end

  test "should normalize tag" do
    t = create_tag_text text: '#test '
    assert_equal 'test', t.reload.text
  end

  test "should get tags" do
    t = create_team
    p = create_project team: t
    tt = create_tag_text team_id: t.id
    t1 = create_tag tag: tt.id, annotated: create_project_media(project: p)
    t2 = create_tag tag: tt.id, annotated: create_project_media(project: p)
    t3 = create_tag tag: tt.id, annotated: create_project_media(project: p)
    t4 = create_tag tag: tt.id
    assert_equal 3, tt.reload.tags_count
    assert_equal [t1, t2, t3].sort, tt.reload.tags.to_a.sort
  end

  test "should destroy tags when tag text is destroyed" do
    t = create_team
    p = create_project team: t
    tt = create_tag_text team_id: t.id
    3.times { create_tag(tag: tt.id, annotated: create_project_media(project: p)) }
    3.times { create_tag(tag: tt.id) }
    assert_difference 'Tag.length', -3 do
      tt.destroy
    end
  end

  test "should update tags when tag text is updated" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tt = create_tag_text text: 'foo', team_id: t.id
    t1 = create_tag tag: tt.id, annotated: pm
    t2 = create_tag tag: tt.id
    t1t1 = t1.reload.updated_at
    t2t1 = t2.reload.updated_at
    sleep 2
    tt = TagText.find(tt.id)
    tt.text = 'bar'
    tt.save!
    t1t2 = t1.reload.updated_at
    t2t2 = t2.reload.updated_at
    assert t1t2 > t1t1
    assert_equal t2t1, t2t2
  end

  test "should belong to team" do
    t = create_team
    tt = create_tag_text team_id: t.id
    assert_equal t, tt.team
  end

  test "should delete tag when team is deleted" do
    t = create_team
    create_tag_text team_id: t.id
    assert_difference 'TagText.count', -1 do
      t.destroy
    end
  end

  test "should not be teamwide by default" do
    tt = create_tag_text
    assert !tt.teamwide
  end

  test "should merge tags if tag is updated to existing text" do
    t = create_team
    p = create_project team: t
    tt1 = create_tag_text text: 'foo', team_id: t.id
    tt2 = create_tag_text text: 'bar', team_id: t.id
    t1 = create_tag tag: tt1.id, annotated: create_project_media(project: p)
    t2 = create_tag tag: tt1.id, annotated: create_project_media(project: p)
    assert_equal 'foo', t1.reload.tag_text
    assert_equal 'foo', t2.reload.tag_text
    assert_equal 0, tt2.reload.tags_count

    assert_difference 'TagText.count', -1 do
      tt1.text = 'bar'
      tt1.save!
    end

    assert_equal 'bar', t1.reload.tag_text
    assert_equal 'bar', t2.reload.tag_text
    assert_equal 2, tt2.reload.tags_count
  end

  test "should cache tags count" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    pm2 = create_project_media project: p
    tt = create_tag_text team_id: t.id
    assert_equal 0, tt.reload.tags_count
    t = create_tag tag: tt.id, annotated: pm
    assert_equal 1, tt.reload.tags_count
    create_tag tag: tt.id, annotated: pm2
    assert_equal 2, tt.reload.tags_count
    t.destroy
    assert_equal 1, tt.reload.tags_count
  end
end
