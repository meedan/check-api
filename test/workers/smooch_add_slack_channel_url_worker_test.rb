require_relative '../test_helper'

class SmoochAddSlackChannelUrlWorkerTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test 'should set fields for annotation if annotation exists' do
    create_annotation_type_and_fields('Smooch User', { 'Slack Channel URL' => ['Text'] })
    a = create_dynamic_annotation annotation_type: 'smooch_user'
    assert_nil a.reload.get_field_value('smooch_user_slack_channel_url')
    url = random_url
    SmoochAddSlackChannelUrlWorker.new.perform(a.id, { smooch_user_slack_channel_url: url }.to_json)
    assert_equal url, a.reload.get_field_value('smooch_user_slack_channel_url')
  end
end 
