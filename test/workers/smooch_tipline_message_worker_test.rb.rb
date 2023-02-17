require_relative '../test_helper'

class SmoochTiplineMessageWorkerTest < ActiveSupport::TestCase
  def setup
    super

    setup_smooch_bot
  end

  def minimal_message
    {'_id' => @msg_id}
  end

  def minimal_payload
    {
      'trigger' => 'message:delivery:channel',
      'app' => { '_id' => @app_id },
      'appUser' => { '_id' => random_string },
      'message' => minimal_message
    }
  end

  test "should attempt to save a tipline message, without erroring" do
    assert_nothing_raised do
      SmoochTiplineMessageWorker.new.perform(minimal_message, minimal_payload)
    end
  end

  test "should prepare the smoochbot installation before the model pulls attribtues from it" do
    Bot::Smooch.expects(:get_installation).with(Bot::Smooch.installation_setting_id_keys, @app_id)

    SmoochTiplineMessageWorker.new.perform(minimal_message, minimal_payload)
  end

  test "should pass event from the cache fallback template" do
    Rails.cache.write("smooch:original:#{@msg_id}", {'fallback_template' => 'newsletter_example_event'}.to_json)

    assert_equal 0, TiplineMessage.count

    SmoochTiplineMessageWorker.new.perform(minimal_message, minimal_payload)

    assert_equal 1, TiplineMessage.count
    assert_equal 'newsletter_example_event', TiplineMessage.last.event
  end

  test "should pass nil event if parsing from cache fails" do
    Rails.cache.write("smooch:original:#{@msg_id}", 'fake string')

    assert_equal 0, TiplineMessage.count

    SmoochTiplineMessageWorker.new.perform(minimal_message, minimal_payload)

    assert_equal 1, TiplineMessage.count
    assert_nil TiplineMessage.last.event
  end
end
