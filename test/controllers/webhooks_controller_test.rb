require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class WebhooksControllerTest < ActionController::TestCase
  def setup
    super
    BotUser.delete_all
    @controller = Api::V1::WebhooksController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    settings = [
      { name: 'smooch_app_id', label: 'Smooch App ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_key_id', label: 'Smooch Secret Key: Key ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_secret', label: 'Smooch Secret Key: Secret', type: 'string', default: '' },
      { name: 'smooch_webhook_secret', label: 'Smooch Webhook Secret', type: 'string', default: '' },
      { name: 'smooch_template_namespace', label: 'Smooch Template Namespace', type: 'string', default: '' },
    ]
    @team = create_team
    @bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: settings, set_events: []
    settings = {
      'smooch_webhook_secret' => 'test',
      'smooch_app_id' => random_string,
      'smooch_secret_key_key_id' => random_string,
      'smooch_secret_key_secret' => random_string,
      'smooch_template_namespace' => random_string
    }
    @installation = create_team_bot_installation user_id: @bot.id, settings: settings, team_id: @team.id
  end

  test "should return error if bot does not exist" do
    stub_configs({ 'checkdesk_base_url_private' => 'http://test.host' }) do
      get :index, params: { name: :test }
      assert_response 404
    end
  end

  test "should return error if request is not valid" do
    stub_configs({ 'checkdesk_base_url_private' => 'http://test.host' }) do
      get :index, params: { name: :smooch }
      assert_response 400
    end
  end

  test "should make successful request to bot" do
    stub_configs({ 'checkdesk_base_url_private' => 'http://test.host' }) do
      @request.headers['X-API-Key'] = 'test'
      get :index, params: { name: :smooch }
      assert_response :success
    end
  end

  test "should save Pender response through webhook" do
    Team.any_instance.stubs(:get_limits_keep).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t
    pm.create_all_archive_annotations
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys

    payload = { type: 'screenshot', url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CheckConfig.get('secret_token'), payload)
    @request.headers['X-Signature'] = sig
    post :index, params: { name: :keep }, body: payload
    assert_response :success
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))
    assert_equal 'http://pender/screenshot.png', f['screenshot_url']
    Team.any_instance.unstub(:get_limits_keep)
  end

  test "should return error and not save Pender response through webhook if link does not exist" do
    Team.any_instance.stubs(:get_limits_keep).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    pender_response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: pender_response)

    l = create_link url: url
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t
    pm.create_all_archive_annotations
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))

    assert_equal [], f.keys

    payload = { url: 'http://anothertest.com', screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CheckConfig.get('secret_token'), payload)
    @request.headers['X-Signature'] = sig

    post :index, params: { name: :keep }, body: payload

    assert_equal '425', response.code
    assert_match /not found/, response.body
    assert_equal 13, JSON.parse(response.body)['errors'].first['code']
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys
  end

  test "should return error and not save Pender response through webhook if there is no project media" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    pender_response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: pender_response)
    l = create_link url: url

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CheckConfig.get('secret_token'), payload)
    @request.headers['X-Signature'] = sig

    post :index, params: { name: :keep }, body: payload

    assert_equal '425', response.code
    assert_match /not found/, response.body
    assert_equal 13, JSON.parse(response.body)['errors'].first['code']
  end

  test "should return error and not save Pender response through webhook if there is no annotation" do
    Team.any_instance.stubs(:get_limits_keep).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    pender_response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: pender_response)
    l = create_link url: url
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CheckConfig.get('secret_token'), payload)
    @request.headers['X-Signature'] = sig

    post :index, params: { name: :keep }, body: payload

    assert_equal '425', response.code
    assert_match /not found/, response.body
    assert_equal 13, JSON.parse(response.body)['errors'].first['code']
  end

  # This represents a team uninstalling Keep on a workspace. We probably want to
  # raise a 404 or something similar, but for simplicity sake (for now) we return 425
  # like the other expected-to-be-resolved-with-time issues since even though we don't
  # expect this to be resolved with time we also don't expect it to happen often
  test "should not save Pender response through webhook if team is not allowed" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    pender_response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: pender_response)
    l = create_link url: url
    t = create_team
    t.set_limits_keep = false
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    pm = create_project_media media: l, team: t
    pm.create_all_archive_annotations

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CheckConfig.get('secret_token'), payload)
    @request.headers['X-Signature'] = sig

    post :index, params: { name: :keep }, body: payload

    assert_equal '425', response.code
    assert_match /not found/, response.body
    assert_equal 13, JSON.parse(response.body)['errors'].first['code']
  end

  test "should ignore some WhatsApp Cloud API requests" do
    payload = {
      object: 'whatsapp_business_account',
      entry: [
        {
          id: '123456',
          changes: [
            {
              value: {
                messaging_product: 'whatsapp',
                metadata: {
                  display_phone_number: '123456',
                  phone_number_id: '123456'
                },
                statuses: [
                  {
                    id: 'wamid.123456==',
                    status: 'read',
                    timestamp: '1689633253',
                    recipient_id: "654321"
                  }
                ]
              },
              field: 'messages'
            }
          ]
        }
      ]
    }

    post :index, params: { name: :smooch }.merge(payload), body: payload

    assert_equal '200', response.code
    assert_match /ignored/, response.body
  end

  test "should process Alegre webhook" do
    redis = Redis.new(REDIS_CONFIG)
    redis.del('alegre:webhook:foo')
    id = random_number
    payload = { 'action' => 'audio', 'data' => {'requested' => { 'id' => 'foo', 'context' => { 'project_media_id' => id } }} }
    assert_nil redis.lpop('alegre:webhook:foo')

    post :index, params: { name: :alegre, token: CheckConfig.get('alegre_token') }, body: payload.to_json
    response = JSON.parse(redis.lpop('alegre:webhook:foo'))
    assert_equal 'foo', response.dig('data', 'requested', 'id')
    expectation = payload
    assert_equal expectation, response
  end

  test "should process Alegre callback webhook with is_shortcircuited_search_result_callback" do
    id = random_number
    payload = { 'action' => 'audio', 'data' => {'is_shortcircuited_search_result_callback' => true, 'item' => { 'callback_url' => '/presto/receive/add_item', 'id' => id.to_s }} }
    Bot::Alegre.stubs(:process_alegre_callback).returns({})
    post :index, params: { name: :alegre, token: CheckConfig.get('alegre_token') }, body: payload.to_json
    assert_equal '200', response.code
    assert_match /success/, response.body
  end

  test "should process Alegre callback webhook with is_search_result_callback" do
    id = random_number
    payload = { 'action' => 'audio', 'data' => {'is_search_result_callback' => true, 'item' => { 'callback_url' => '/presto/receive/add_item', 'id' => id.to_s }} }
    Bot::Alegre.stubs(:process_alegre_callback).returns({})
    post :index, params: { name: :alegre, token: CheckConfig.get('alegre_token') }, body: payload.to_json
    assert_equal '200', response.code
    assert_match /success/, response.body
  end

  test "should report error if can't process Alegre webhook" do
    CheckSentry.expects(:notify).once
    post :index, params: { name: :alegre, token: CheckConfig.get('alegre_token') }, body: {foo: "bar"}.to_json
  end
end
