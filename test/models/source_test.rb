require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SourceTest < ActiveSupport::TestCase
  def setup
    super
    Annotation.delete_index
    Annotation.create_index
    sleep 1
  end

  test "should create source" do
    assert_difference 'Source.count' do
      create_source
    end
  end

  test "should not save source without name" do
    source = Source.new
    assert_not  source.save
  end

  test "should create version when source is created" do
    s = create_source
    assert_equal 1, s.versions.size
  end

  test "should create version when source is updated" do
    s = create_source
    s.slogan = 'test'
    s.save!
    assert_equal 2, s.versions.size
  end

  test "should have accounts" do
    a1 = create_valid_account
    a2 = create_valid_account
    s = create_source
    assert_equal [], s.accounts
    s.accounts << a1
    s.accounts << a2
    assert_equal [a1, a2], s.accounts
  end

  test "should have project sources" do
    ps1 = create_project_source
    ps2 = create_project_source
    s = create_source
    assert_equal [], s.project_sources
    s.project_sources << ps1
    s.project_sources << ps2
    assert_equal [ps1, ps2], s.project_sources
  end

  test "should have projects" do
    p1 = create_project
    p2 = create_project
    ps1 = create_project_source project: p1
    ps2 = create_project_source project: p2
    s = create_source
    assert_equal [], s.project_sources
    s.project_sources << ps1
    s.project_sources << ps2
    assert_equal [p1, p2], s.projects
  end

  test "should have user" do
    u = create_user
    s = create_source user: u
    assert_equal u, s.user
  end

  test "should have annotations" do
    s = create_source
    c1 = create_comment
    c2 = create_comment
    c3 = create_comment
    s.add_annotation(c1)
    s.add_annotation(c2)
    sleep 1
    assert_equal [c1.id, c2.id].sort, s.reload.annotations.map(&:id).sort
  end
end
