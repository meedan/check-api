require_relative '../test_helper'

class SavedSearchTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    super
    SavedSearch.delete_all
  end

  test "should create saved search" do
    assert_difference 'SavedSearch.count' do
      create_saved_search
    end
  end

  test "should not create saved search if title is not present" do
    assert_no_difference 'SavedSearch.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_saved_search title: nil
      end
    end
  end

  test "should not create saved search if team is not present" do
    assert_no_difference 'SavedSearch.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_saved_search team: nil
      end
    end
  end

  test "should belong to team" do
    t = create_team
    ss = create_saved_search team: t
    assert_equal t, ss.reload.team
    assert_equal [ss], t.reload.saved_searches
  end

  test "should serialize the filters" do
    ss = create_saved_search filters: { foo: 'bar'}
    assert_equal 'bar', ss.reload.filters['foo']
  end
end
