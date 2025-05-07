require_relative '../test_helper'

class SavedSearchTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    SavedSearch.delete_all
  end

  test "should create saved search" do
    assert_difference 'SavedSearch.count' do
      create_saved_search
    end
  end

  test "should set list type" do
    ss = create_saved_search
    assert_equal 'media', ss.list_type
    create_saved_search list_type: 'article'
    assert_raises ArgumentError do
      create_saved_search list_type: 'invalid'
    end
  end

  test "should validate unique list name based on the team and list type" do
    t = create_team
    assert_difference 'SavedSearch.count', 2 do
      create_saved_search team: t, list_type: 'media', title: 'list_a'
      create_saved_search team: t, list_type: 'article', title: 'list_a'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_saved_search team: t, list_type: 'media', title: 'list_a'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_saved_search team: t, list_type: 'article', title: 'list_a'
    end
    t2 = create_team
    assert_difference 'SavedSearch.count', 2 do
      create_saved_search team: t2, list_type: 'media', title: 'list_a'
      create_saved_search team: t2, list_type: 'article', title: 'list_a'
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

  test "should count number of items" do
    ss = create_saved_search
    assert_equal 0, ss.items_count
  end

  test "should not crash if filter is invalid" do
    ss = create_saved_search filters: { team_tasks: [{ id: '', task_type: 'single_choice', response: 'NO_VALUE' }] }
    assert_nothing_raised do
      assert_equal 0, ss.items_count
    end
  end
end
