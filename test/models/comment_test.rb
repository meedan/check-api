require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CommentTest < ActiveSupport::TestCase
  def setup
    super
    Comment.delete_index
    Comment.create_index
    sleep 1
  end

  test "should create comment" do
    assert_difference 'Comment.count' do
      create_comment(text: 'test')
    end
  end

  test "should set type automatically" do
    c = create_comment
    assert_equal 'comment', c.type
  end

  test "should have text" do
    assert_no_difference 'Comment.count' do
      create_comment(text: nil)
      create_comment(text: '')
    end
  end
end
