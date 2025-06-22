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

  test "should unsubscribe user from newsletters when error 131050 is received" do
    t = create_team
    RequestStore.store[:smooch_bot_provider] = 'CAPI'
    config = {
      smooch_template_namespace: 'abcdef',
      capi_verify_token: '123456',
      capi_whatsapp_business_account_id: '123456',
      capi_permanent_token: '123456',
      capi_phone_number_id: '123456',
      capi_phone_number: '123456',
      team_id: t.id,
      smooch_workflows: [
        {
          'smooch_workflow_language' => 'en',
          'smooch_message_smooch_bot_greetings' => 'Hello!',
          'smooch_message_smooch_bot_tos' => {
            'greeting' => 'Send 9 to read the terms of service.',
            'content' => 'Custom terms of service.'
          }
        }
      ]
    }.with_indifferent_access
    RequestStore.store[:smooch_bot_settings] = config
    # Cloned a request from CloudWatch
    request =  {
      "object": "whatsapp_business_account",
      "entry": [
          {
              "id": "112799291857759",
              "changes": [
                  {
                      "value": {
                          "messaging_product": "whatsapp",
                          "metadata": {
                              "display_phone_number": "6289680060088",
                              "phone_number_id": "183815411472659"
                          },
                          "statuses": [
                              {
                                  "id": "wamid.HBgNNjI4MzE4MDc4MzE3MBUCABEYEkQxOUJFMzUwN0M1NjJDNzg1MwA=",
                                  "status": "failed",
                                  "timestamp": "1750224806",
                                  "recipient_id": "6283180783170",
                                  "errors": [
                                      {
                                          "code": 131050,
                                          "title": "Unable to deliver the message. This recipient has chosen to stop receiving marketing messages on WhatsApp from your business",
                                          "message": "Unable to deliver the message. This recipient has chosen to stop receiving marketing messages on WhatsApp from your business",
                                          "error_data": {
                                              "details": "Unable to deliver the message. This recipient has chosen to stop receiving marketing messages on WhatsApp from your business"
                                          },
                                          "href": "https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/"
                                      }
                                  ]
                              }
                          ]
                      },
                      "field": "messages"
                  }
              ]
          }
      ],
      "format": "json",
      "name": "smooch",
      "webhook": {
          "object": "whatsapp_business_account",
          "entry": [
              {
                  "id": "112799291857759",
                  "changes": [
                      {
                          "value": {
                              "messaging_product": "whatsapp",
                              "metadata": {
                                  "display_phone_number": "6289680060088",
                                  "phone_number_id": "183815411472659"
                              },
                              "statuses": [
                                  {
                                      "id": "wamid.HBgNNjI4MzE4MDc4MzE3MBUCABEYEkQxOUJFMzUwN0M1NjJDNzg1MwA=",
                                      "status": "failed",
                                      "timestamp": "1750224806",
                                      "recipient_id": "6283180783170",
                                      "errors": [
                                          {
                                              "code": 131050,
                                              "title": "Unable to deliver the message. This recipient has chosen to stop receiving marketing messages on WhatsApp from your business",
                                              "message": "Unable to deliver the message. This recipient has chosen to stop receiving marketing messages on WhatsApp from your business",
                                              "error_data": {
                                                  "details": "Unable to deliver the message. This recipient has chosen to stop receiving marketing messages on WhatsApp from your business"
                                              },
                                              "href": "https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/"
                                          }
                                      ]
                                  }
                              ]
                          },
                          "field": "messages"
                      }
                  ]
              }
          ]
      }
    }
    # Subscribe user in newsletter based on uid created from CloudWatch request()
    uid = "123456:6283180783170"
    ts = create_tipline_subscription team_id: t.id, uid: uid
    assert_difference 'TiplineSubscription.count', -1 do
      Bot::Smooch.run(request.to_json)
    end
    assert_nil TiplineSubscription.find_by_id(ts.id)
  end
end
