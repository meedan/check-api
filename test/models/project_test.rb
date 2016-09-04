require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectTest < ActiveSupport::TestCase

  test "should create project" do
    assert_difference 'Project.count' do
      create_project
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
    file = 'http://dummyimage.com/100x100/000/fff.png'
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
end
