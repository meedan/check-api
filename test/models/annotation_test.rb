require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CommentTest < ActiveSupport::TestCase
  def setup
    super
    Annotation.delete_index
    Annotation.create_index
    sleep 1
  end

  test "should not create generic annotation" do
    assert_no_difference 'Annotation.count' do
      assert_raises RuntimeError do
        create_annotation
      end
    end
  end

  test "should have empty content by default" do
    assert_equal '{}', Annotation.new.content
  end
end
