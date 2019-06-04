require_relative '../test_helper'

class MontageBaseTest < ActiveSupport::TestCase
  test "should have created method" do
    u = create_user
    assert_kind_of String, u.extend(Montage::Base).created
  end

  test "should have modified method" do
    u = create_user
    assert_kind_of String, u.extend(Montage::Base).modified
  end
end 
