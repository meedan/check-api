require 'test_helper'

class ProjectTest < ActiveSupport::TestCase

  test "should create project" do
    assert_difference 'Project.count' do
      create_project
    end
  end

  test "should not save project without title" do
    project = Project.new
    assert_not  project.save
  end

end
