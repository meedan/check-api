require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "should not save account without url" do
    account = Account.new
    assert_not  account.save
  end
end
