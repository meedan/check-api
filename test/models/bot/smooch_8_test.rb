require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch8Test < ActiveSupport::TestCase
  def setup
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
  end

  def teardown
  end

  test "should not store duplicated Smooch requests" do
    create_annotation_type_and_fields('Smooch', {
      'Data' => ['JSON', false],
      'Message Id' => ['Text', false]
    })

    pm = create_project_media
    fields = { 'smooch_message_id' => random_string, 'smooch_data' => '{}' }
    assert_difference 'Annotation.count' do
      Bot::Smooch.create_smooch_annotations(pm, nil, fields)
    end
    assert_no_difference 'Annotation.count' do
      Bot::Smooch.create_smooch_annotations(pm, nil, fields)
    end
  end
end
