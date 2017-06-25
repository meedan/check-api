require_relative '../test_helper'

class RootLevelTest < ActiveSupport::TestCase
  test "should find" do
    assert_nothing_raised do
      RootLevel.find('')
    end
  end
end
