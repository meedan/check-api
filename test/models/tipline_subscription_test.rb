require_relative '../test_helper'

class TiplineSubscriptionTest < ActiveSupport::TestCase
  def setup
    TiplineSubscription.delete_all
  end

  test "should keep versions after tipline subscription is deleted" do
    with_versioning do
      ts = nil
      assert_difference 'Version.count', 1 do
        ts = create_tipline_subscription
      end
      ts = TiplineSubscription.find(ts.id)
      assert_difference 'Version.count', 1 do
        ts.destroy!
      end
    end
  end
end
