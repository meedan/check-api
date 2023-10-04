require_relative '../test_helper'

class BlockedTiplineUserTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test 'should create blocked tipline user' do
    assert_difference 'BlockedTiplineUser.count' do
      create_blocked_tipline_user
    end
  end

  test 'should not create blocked tipline user if UID is blank' do
    assert_no_difference 'BlockedTiplineUser.count' do
      assert_raises ActiveRecord::NotNullViolation do
        create_blocked_tipline_user uid: nil
      end
    end
  end

  test 'should not block the same user more than once' do
    uid = random_string
    create_blocked_tipline_user uid: uid
    assert_no_difference 'BlockedTiplineUser.count' do
      assert_raises ActiveRecord::RecordNotUnique do
        create_blocked_tipline_user uid: uid
      end
    end
  end
end
