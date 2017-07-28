require_relative '../test_helper'

class AccountSearchTest < ActiveSupport::TestCase
  def setup
    super
    AccountSearch.delete_index
    AccountSearch.create_index
    sleep 1
  end

  test "should create account" do
    assert_difference 'AccountSearch.length' do
      create_account_search
    end
  end

  test "should set type automatically" do
    a = create_account_search
    assert_equal 'accountsearch', a.annotation_type
  end
end
