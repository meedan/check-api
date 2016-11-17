require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class BounceTest < ActiveSupport::TestCase
  def setup
    super
    Bounce.destroy_all
  end

  test "should create bounce" do
    assert_difference 'Bounce.count' do
      create_bounce
    end
  end

  test "should not create duplicate bounce" do
    assert_difference 'Bounce.count' do
      create_bounce email: 'test@bounce.com'
    end
    assert_no_difference 'Bounce.count' do
      assert_raises ActiveRecord::RecordNotUnique do
        create_bounce email: 'test@bounce.com'
      end
    end
  end

  test "should not create empty bounce" do
    assert_no_difference 'Bounce.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_bounce email: nil
      end
    end
  end

  test "should remove bounces from list" do
    create_bounce email: 'bounce@check.com'
    assert_equal ['test@check.com'], Bounce.remove_bounces(['bounce@check.com', 'test@check.com'])
  end

  test "should remove bounces from single item" do
    create_bounce email: 'bounce@check.com'
    assert_equal [], Bounce.remove_bounces('bounce@check.com')
  end
end
