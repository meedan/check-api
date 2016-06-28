require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AbilityTest < ActiveSupport::TestCase
  test "should instantiate" do
    u = create_user
    assert_kind_of Ability, Ability.new(u)
  end
end
