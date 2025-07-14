require_relative '../test_helper'

class CheckStatisticsTest < ActiveSupport::TestCase
  def setup
    Rails.cache.delete_matched("check_statistics:whatsapp_conversations:*")
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
    @team = create_team
    bot = create_team_bot login: 'smooch', name: 'Smooch', set_approved: true
    settings = {
      capi_whatsapp_business_account_id: '123456',
      capi_phone_number: '12345678',
      capi_permanent_token: '654321'
    }
    create_team_bot_installation team_id: @team.id, user_id: bot.id, settings: settings
    @from = Time.parse('2023-01-01').beginning_of_month.to_date
    @to = Time.parse('2023-01-01').end_of_month.to_date
    @url = 'https://graph.facebook.com/v17.0/123456?fields=conversation_analytics.start(1672531200).end(1675123200).granularity(DAILY).phone_numbers(12345678)&access_token=654321'
  end

  def teardown
  end

  test 'should calculate number of all WhatsApp conversations' do
    WebMock.stub_request(:get, @url).to_return(status: 200, body: {
      conversation_analytics: {
        data: [
          {
            data_points: [
              {
                start: 1688454000,
                end: 1688540400,
                conversation: 39,
                cost: 0.8866
              },
              {
                start: 1688281200,
                end: 1688367600,
                conversation: 19,
                cost: 0
              },
              {
                start: 1688367600,
                end: 1688454000,
                conversation: 1117,
                cost: 68.465
              },
              {
                start: 1688540400,
                end: 1688626800,
                conversation: 1101,
                cost: 66.9023
              },
              {
                start: 1688194800,
                end: 1688281200,
                conversation: 24,
                cost: 0.1875
              }
            ]
          }
        ]
      },
      id: '123456'
    }.to_json)
    assert_equal '-', CheckStatistics.number_of_whatsapp_conversations(@team.id, @from, @to, 'all')
  end

  test 'should not calculate number of WhatsApp conversations if WhatsApp Insights API returns an error' do
    WebMock.stub_request(:get, @url).to_return(status: 400, body: { error: 'Error' }.to_json)
    assert_equal '-', CheckStatistics.number_of_whatsapp_conversations(@team.id, @from, @to)
  end

  test 'should not calculate number of WhatsApp conversations if there is no tipline' do
    WebMock.stub_request(:get, @url).to_return(status: 400, body: { error: 'Error' }.to_json)
    assert_nil CheckStatistics.number_of_whatsapp_conversations(create_team.id, @from, @to)
  end

  test 'should calculate number of delivered newsletters' do
    WebMock.stub_request(:get, /graph\.facebook\.com/).to_return(status: 400, body: { error: 'Error' }.to_json)
    create_tipline_message team_id: @team.id, event: 'newsletter', direction: :outgoing, state: 'sent'
    create_tipline_message team_id: @team.id, event: 'newsletter', direction: :outgoing, state: 'delivered'
    data = CheckStatistics.get_statistics(Time.now.yesterday, Time.now.tomorrow, @team.id, 'whatsapp', 'en')
    assert_equal 1, data[:newsletters_delivered]
  end

  test 'should calculate number of WhatsApp user-initiated and business-initiated conversations' do
    url = 'https://graph.facebook.com/v17.0/123456?fields=conversation_analytics.start(1672531200).end(1675123200).granularity(DAILY).dimensions(CONVERSATION_DIRECTION).phone_numbers(12345678)&access_token=654321'
    WebMock.stub_request(:get, url).to_return(status: 200, body: {
      conversation_analytics: {
        data: [
          {
            data_points: [
              {
                start: 1688454000,
                end: 1688540400,
                conversation: 40,
                conversation_direction: 'USER_INITIATED',
                cost: 0.8866
              },
              {
                start: 1688281200,
                end: 1688367600,
                conversation: 10,
                conversation_direction: 'BUSINESS_INITIATED',
                cost: 0
              }
            ]
          }
        ]
      },
      id: '123456'
    }.to_json)
    assert_equal '-', CheckStatistics.number_of_whatsapp_conversations(@team.id, @from, @to, 'user')
    assert_equal '-', CheckStatistics.number_of_whatsapp_conversations(@team.id, @from, @to, 'business')
  end
end
