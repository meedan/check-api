require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch8Test < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test "should not store duplicated Smooch requests" do
    pm = create_project_media
    fields = { 'smooch_message_id' => random_string, 'smooch_data' => '{}' }
    assert_difference 'TiplineRequest.count' do
      Bot::Smooch.create_smooch_annotations(pm, nil, fields, true)
    end
    assert_no_difference 'TiplineRequest.count' do
      Bot::Smooch.create_smooch_annotations(pm, nil, fields, true)
    end
  end
end
