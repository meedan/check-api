require_relative '../test_helper'

class TiplineNewsletterDeliveryTest < ActiveSupport::TestCase
  def setup
    @delivery = TiplineNewsletterDelivery.new(
      recipients_count: 100,
      content: 'Test',
      started_sending_at: Time.now.ago(1.minute),
      finished_sending_at: Time.now,
      tipline_newsletter: create_tipline_newsletter
    )
  end

  def teardown
  end

  test 'should persist tipline newsletter delivery' do
    assert_difference 'TiplineNewsletterDelivery.count' do
      @delivery.save!
    end
  end

  test 'should be a valid newsletter delivery' do
    assert @delivery.valid?
  end

  test 'should belong to a newsletter' do
    assert_kind_of TiplineNewsletter, @delivery.tipline_newsletter
  end
end
