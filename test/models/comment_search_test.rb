require_relative '../test_helper'

class CommentSearchTest < ActiveSupport::TestCase
  def setup
    super
    CommentSearch.delete_index
    CommentSearch.create_index
    sleep 1
  end

  test "should create comment" do
    assert_difference 'CommentSearch.length' do
      create_comment_search(text: 'test')
    end
  end

  test "should set type automatically" do
    t = create_comment_search
    assert_equal 'commentsearch', t.annotation_type
  end

  test "should have text" do
    assert_no_difference 'CommentSearch.length' do
      assert_raise RuntimeError do
        create_comment_search(text: nil)
      end
      assert_raise RuntimeError do
        create_comment_search(text: '')
      end
    end
  end

end
