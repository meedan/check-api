require_relative '../test_helper'

class MediaSearchTest < ActiveSupport::TestCase
  def setup
    super
    MediaSearch.delete_index
    MediaSearch.create_index
    sleep 1
  end

  test "should create media search" do
    assert_difference 'MediaSearch.length' do
      create_media_search
    end
  end

  test "should set type automatically" do
    m = create_media_search
    assert_equal 'mediasearch', m.annotation_type
  end

  test "should re-index data" do
    Rails.logger.stubs(:debug).raises(StandardError)
    mapping_keys = [MediaSearch, CommentSearch, TagSearch, DynamicSearch]
    source_index = CheckElasticSearchModel.get_index_name
    target_index = "#{source_index}_reindex"
    MediaSearch.delete_index(target_index)
    m = create_media_search
    sleep 1
    assert_equal 1, MediaSearch.length
    # Test migrate data into target index
    MediaSearch.migrate_es_data(source_index, target_index, mapping_keys)
    sleep 1
    MediaSearch.index_name = target_index
    assert_equal 1, MediaSearch.length
    MediaSearch.delete_index
    MediaSearch.index_name = source_index
    MediaSearch.create_index

    Rails.logger.stubs(:error).once
    sleep 1
    MediaSearch.migrate_es_data(source_index, target_index, mapping_keys)
    Rails.logger.unstub(:error)

    MediaSearch.delete_index(target_index)
    MediaSearch.index_name = source_index
    MediaSearch.create_index
    m = create_media_search
    CheckElasticSearchModel.reindex_es_data
    sleep 1
    MediaSearch.index_name = source_index
    assert_equal 1, MediaSearch.length
    Rails.logger.unstub(:debug)
  end

end
