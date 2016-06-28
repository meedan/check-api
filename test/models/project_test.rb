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

  test "should get user id through callback" do
    p = create_project
    assert_nil p.send(:user_id_callback, 'test')
    u = create_user name: 'test'
    assert_equal u.id, p.send(:user_id_callback, 'test')
  end
end
