require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class TagSearchTest < ActiveSupport::TestCase
  def setup
    super
    TagSearch.delete_index
    TagSearch.create_index
    sleep 1
  end

  test "should create tag" do
    assert_difference 'TagSearch.length' do
      create_tag_search(tag: 'test')
    end
  end

  test "should set type automatically" do
    t = create_tag_search
    assert_equal 'tagsearch', t.annotation_type
  end

  test "should have tag" do
    assert_no_difference 'TagSearch.length' do
      assert_raise RuntimeError do
        create_tag_search(tag: nil)
      end
      assert_raise RuntimeError do
        create_tag_search(tag: '')
      end
    end
  end

end
