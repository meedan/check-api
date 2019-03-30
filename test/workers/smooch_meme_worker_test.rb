require_relative '../test_helper'

class SmoochMemeWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}/
    field_names = ['image', 'overlay', 'published_at', 'headline', 'body', 'status', 'operation', 'last_error']
    fields = {}
    field_names.each{ |fn| fields[fn] = ['text', false] }
    create_annotation_type_and_fields('memebuster', fields)
  end

  test "should send message to Smooch user" do
    Sidekiq::Testing.inline!
    Bot::Smooch.stubs(:send_meme_to_smooch_users).once
    d = create_dynamic_annotation annotation_type: 'memebuster'
    assert_nothing_raised do
      SmoochMemeWorker.perform_async(d.id)
    end
    Bot::Smooch.unstub(:send_meme_to_smooch_users)
  end

  test "should save error after many retries" do
    d = create_dynamic_annotation annotation_type: 'memebuster'
    assert d.get_field_value('memebuster_last_error').blank?
    SmoochMemeWorker.retry_callback({ 'args' => [d.id], 'error_message' => 'Test' })
    assert_match /Test/, d.get_field_value('memebuster_last_error')
  end
end
