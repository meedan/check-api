require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectMediaTest < ActiveSupport::TestCase
  test "should create project media" do
    assert_difference 'ProjectMedia.count' do
      create_project_media
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
