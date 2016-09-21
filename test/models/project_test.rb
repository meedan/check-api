require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectTest < ActiveSupport::TestCase

  test "should create project" do
    assert_difference 'Project.count' do
      create_project
    end
    u = create_user
    t = create_team current_user: u
    assert_difference 'Project.count' do
      p = create_project team: t, current_user: u
    end
  end

  test "should not create project by contributor" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'contributor'
    assert_raise RuntimeError do
      create_project team: t, current_user: u, context_team: t
    end
  end

  test "should update and destroy team" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t, current_user: u
    p.current_user = u
    p.title = 'Project A'; p.save!
    p.reload
    assert_equal p.title, 'Project A'
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'
    assert_raise RuntimeError do
      p.current_user = u2
      p.save!
    end
    assert_raise RuntimeError do
      p.current_user = u2
      p.destroy!
    end
    own_project = create_project team:t, user: u2
    own_project.current_user = u2
    own_project.title = 'Project A'
    own_project.save!
    assert_equal own_project.title, 'Project A'
    assert_nothing_raised RuntimeError do
      own_project.current_user = u2
      own_project.destroy!
    end
    assert_nothing_raised RuntimeError do
      p.current_user = u
      p.destroy!
    end
  end

  test "non memebers should not read project in private team" do
    u = create_user
    t = create_team current_user: create_user
    p = create_project team: t
    pu = create_user
    pt = create_team current_user: pu, private: true
    pp = create_project team: pt
    Project.find_if_can(p.id, u, t)
    assert_raise CheckdeskPermissions::AccessDenied do
      Project.find_if_can(pp.id, u, pt)
    end
    Project.find_if_can(pp.id, pu, pt)
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      Project.find_if_can(pp.id, pu, pt)
    end
  end

  test "should not save project without title" do
    project = Project.new
    assert_not project.save
  end

  test "should have user" do
    assert_kind_of User, create_project.user
  end

  test "should have media" do
    m1 = create_valid_media
    m2 = create_valid_media
    p = create_project
    p.medias << m1
    p.medias << m2
    assert_equal [m1, m2], p.medias
  end

  test "should have project sources" do
    ps1 = create_project_source
    ps2 = create_project_source
    p = create_project
    p.project_sources << ps1
    p.project_sources << ps2
    assert_equal [ps1, ps2], p.project_sources
  end

  test "should have sources" do
    s1 = create_source
    s2 = create_source
    ps1 = create_project_source(source: s1)
    ps2 = create_project_source(source: s2)
    p = create_project
    p.project_sources << ps1
    p.project_sources << ps2
    assert_equal [s1, s2], p.sources
  end

  test "should have annotations" do
    Annotation.delete_index
    Annotation.create_index
    p = create_project
    c1 = create_comment
    c2 = create_comment
    c3 = create_comment
    p.add_annotation(c1)
    p.add_annotation(c2)
    sleep 1
    assert_equal [c1.id, c2.id].sort, p.reload.annotations.map(&:id).sort
  end

  test "should get user id through callback" do
    p = create_project
    assert_nil p.send(:user_id_callback, 'test@test.com')
    u = create_user email: 'test@test.com'
    assert_equal u.id, p.send(:user_id_callback, 'test@test.com')
  end

  test "should get team from callback" do
    p = create_project
    assert_equal 2, p.team_id_callback(1, [1, 2, 3])
  end

  test "should get lead image from callback" do
    p = create_project
    assert_nil p.lead_image_callback('')
    file = 'http://checkdesk.org/users/1/photo.png'
    assert_nil p.lead_image_callback(file)
    file = 'http://ca.ios.ba/files/others/rails.png'
    assert_not_nil p.lead_image_callback(file)
  end

  test "should not upload a logo that is not an image" do
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project lead_image: 'not-an-image.txt'
      end
    end
  end

  test "should not upload a big logo" do
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project lead_image: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small logo" do
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project lead_image: 'ruby-small.png'
      end
    end
  end

  test "should have a default uploaded image" do
    p = create_project lead_image: nil
    assert_match /project\.png$/, p.lead_image.url
  end

  test "should assign current team to project" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project current_user: nil
    assert_not_equal t, p.team
    p = create_project team: t, current_user: u
    assert_equal t, p.team
  end

  test "should have avatar" do
    p = create_project lead_image: nil
    assert_match /^http/, p.avatar
  end

  test "should have a JSON version" do
    assert_kind_of Hash, create_project.as_json
  end

  test "should create project with team" do
    t1 = create_team
    t2 = create_team
    p = create_project team_id: t2.id
    assert_equal t2, p.reload.team
  end

  test "should set user" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t, user: nil, current_user: nil
    assert_nil p.user
    p = create_project current_user: u, user: nil, team: t
    assert_equal u, p.user
  end
end
