require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectMediaTest < ActiveSupport::TestCase
  test "should create project media" do
    assert_difference 'ProjectMedia.count' do
      create_project_media
    end
  end
end
