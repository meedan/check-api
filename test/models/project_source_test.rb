require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectSourceTest < ActiveSupport::TestCase

  test "should create project source" do
    assert_difference 'ProjectSource.count' do
      create_project_source
    end
  end

end
