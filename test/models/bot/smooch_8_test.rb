require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch8Test < ActiveSupport::TestCase
  def setup
    Sidekiq::Testing.fake!
    RequestStore.store[:skip_cached_field_update] = true
    @team = create_team
    @bot = create_smooch_bot
    @installation = create_team_bot_installation user_id: @bot.id, team_id: @team.id
    Bot::Smooch.get_installation('team_bot_installation_id', @installation.id) { |i| i.id == @installation.id }
  end

  def teardown
  end

  test "should update ticker only when report is actually sent" do
    RequestStore.store[:smooch_bot_provider] = 'CAPI'
    Bot::Smooch.stubs(:send_message_to_user).returns(OpenStruct.new({ body: { messages: [{ id: random_string }] }.to_json }))
    Bot::Smooch.stubs(:send_final_messages_to_user).returns(OpenStruct.new({ body: { messages: [{ id: random_string }] }.to_json }))

    pm = create_project_media team: @team
    tr = create_tipline_request team_id: @team.id
    r = publish_report(pm)
    r.set_fields = { state: 'paused' }.to_json
    r.save!

    assert_equal 0, tr.reload.smooch_report_sent_at
    assert_equal 0, tr.reload.smooch_report_correction_sent_at
    
    Bot::Smooch.send_correction_to_user({}, pm, tr, nil, 'publish', 0)
    assert_equal 0, tr.reload.smooch_report_sent_at
    assert_equal 0, tr.reload.smooch_report_correction_sent_at

    r.set_fields = { state: 'published' }.to_json
    r.save!

    Bot::Smooch.send_correction_to_user({}, pm, tr, nil, 'publish', 0)
    assert_not_equal 0, tr.reload.smooch_report_sent_at
    assert_equal 0, tr.reload.smooch_report_correction_sent_at

    Bot::Smooch.send_correction_to_user({}, pm, tr, Time.now.since(1.minute), 'publish', 1)
    assert_not_equal 0, tr.reload.smooch_report_sent_at
    assert_not_equal 0, tr.reload.smooch_report_correction_sent_at
  end
end
