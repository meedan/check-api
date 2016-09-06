require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectMediaTest < ActiveSupport::TestCase
  test "should create project media" do
    assert_difference 'ProjectMedia.count' do
      create_project_media
    end
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    assert_difference 'ProjectMedia.count' do
      create_project_media project: p, media: m, current_user: u
    end
    # journalist should assign own media only
    tu.role = 'journalist'; tu.save;
    m2 = create_valid_media
    assert_raise RuntimeError do
      create_project_media project: p, media: m, current_user: u
    end
    m2.user_id = u.id;m2.save!
    assert_difference 'ProjectMedia.count' do
      create_project_media project: p, media: m2, current_user: u
    end
  end

  test "should update and destroy project media" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t, current_user: u
    p2 = create_project team: t, current_user: u
    m = create_valid_media project_id: p.id, current_user: u
    pm = m.project_medias.last
    pm.current_user = u
    pm.project_id = p2.id; pm.save!
    pm.reload
    assert_equal pm.project_id, p2.id
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'
    assert_raise RuntimeError do
      pm.current_user = u2
      pm.save!
    end
    assert_raise RuntimeError do
      pm.current_user = u2
      pm.destroy!
    end
    own_media = create_valid_media project_id: p.id, user: u2, current_user: u2
    pm_own = own_media.project_medias.last
    pm_own.current_user = u2
    pm_own.project_id = p2.id; pm_own.save!
    pm_own.reload
    assert_equal pm_own.project_id, p2.id
    assert_nothing_raised RuntimeError do
      pm_own.current_user = u2
      pm_own.destroy!
    end
    assert_nothing_raised RuntimeError do
      pm.current_user = u
      pm.destroy!
    end
  end

  test "should get media from callback" do
    pm = create_project_media
    assert_equal 2, pm.media_id_callback(1, [1, 2, 3])
  end

  test "should get project from callback" do
    tm = create_project_media
    assert_equal 2, tm.project_id_callback(1, [1, 2, 3])
  end

end
