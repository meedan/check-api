require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch8Test < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test "should not store duplicated Smooch requests" do
    t = create_team
    pm = create_project_media team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      fields = { 'smooch_message_id' => random_string, 'smooch_data' => { authorId: random_string, language: 'en' } }
      assert_difference 'TiplineRequest.count' do
        Bot::Smooch.create_tipline_requests(pm, nil, fields, true)
      end
      assert_no_difference 'TiplineRequest.count' do
        Bot::Smooch.create_tipline_requests(pm, nil, fields, true)
      end
    end
  end
end
