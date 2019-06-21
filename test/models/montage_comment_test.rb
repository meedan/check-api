require_relative '../test_helper'

class MontageCommentTest < ActiveSupport::TestCase
  test "should save start seconds as a fragment" do
    c = create_comment.extend(Montage::Comment)
    assert_equal 0.0, c.start_seconds
    c.start_seconds = 120.5
    assert_equal 120.5, c.start_seconds
    assert_equal 't=120.5', c.fragment
  end

  test "should return as JSON" do
    pm = create_project_media
    c = create_comment(annotated: pm).extend(Montage::Comment)
    assert_kind_of Hash, c.comment_as_montage_comment_json
  end
end 
