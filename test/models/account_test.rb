require 'test_helper'

class AccountTest < ActiveSupport::TestCase

  test "should create account" do
    assert_difference 'Account.count' do
      create_account
    end
  end

  test "should not save account without url" do
    account = Account.new
    assert_not  account.save
  end

  test "set pender data for account" do
    account = create_account
    assert_not_empty account.data
  end

end
