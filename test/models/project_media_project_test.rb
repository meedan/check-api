require_relative '../test_helper'

class ProjectMediaProjectTest < ActiveSupport::TestCase
  def setup
    super
  end

  test "should create project media project" do
    assert_difference 'ProjectMediaProject.count', 1 do
      create_project_media_project
    end
  end

  test "should belong to project" do
    p = create_project
    pmp = create_project_media_project project: p
    assert_equal p, pmp.reload.project
  end

  test "should belong to project media" do
    pm = create_project_media
    pmp = create_project_media_project project_media: pm
    assert_equal pm, pmp.reload.project_media
  end

  test "should not add the same project media to the same project more than once" do
    p = create_project
    pm = create_project_media
    assert_difference 'ProjectMediaProject.count' do
      create_project_media_project project: p, project_media: pm
    end
    assert_no_difference 'ProjectMediaProject.count' do
      assert_raises ActiveRecord::RecordNotUnique do
        create_project_media_project project: p, project_media: pm
      end
    end
  end

  test "should create project media project when project media is created" do
    pm = nil
    p = create_project
    assert_difference 'ProjectMediaProject.count' do
      pm = create_project_media project: p
    end
    create_project_media_project project_media: pm
    assert_difference 'ProjectMediaProject.count', -2 do
      pm.destroy!
    end
  end

  test "should remove project media projects when project is deleted" do
    p = create_project
    create_project_media_project project: p
    create_project_media_project project: p
    assert_difference 'ProjectMediaProject.count', -2 do
      p.destroy!
    end
  end

  test "should change project media project when project media is moved" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p1
    pm = ProjectMedia.find(pm.id)
    pm.move_to_project_id = p2.id
    pm.save!
    assert_equal [p2], pm.reload.project_media_projects.map(&:project)
  end

  test "should not destroy project media when project is destroyed" do
    p = create_project
    pm = create_project_media project: p
    assert_equal [p.id], pm.reload.project_ids
    p.destroy!
    assert_empty pm.reload.project_ids
  end

  test "should index a list of project ids in ElasticSearch" do
    setup_elasticsearch
    p1 = create_project
    pm = create_project_media project: p1, disable_es_callbacks: false
    sleep 3
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [p1.id], result.project_id
    p2 = create_project
    pmp = create_project_media_project project_media: pm, project: p2, disable_es_callbacks: false
    sleep 3
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [p1.id, p2.id].sort, result.project_id.sort
    pmp.destroy!
    sleep 3
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [p1.id], result.project_id
  end

  test "should get search object" do
    pmp = create_project_media_project
    assert_kind_of CheckSearch, pmp.check_search_project
  end
end
