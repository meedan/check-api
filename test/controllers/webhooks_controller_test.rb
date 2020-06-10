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
      { name: 'smooch_project_id', label: 'Check Project ID', type: 'number', default: '' }
    ]
    @team = create_team
    @project = create_project team_id: @team.id
    @bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: settings, set_events: []
    settings = {
      'smooch_project_id' => @project.id,
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
      get :index, name: :test
      assert_response 404
    end
  end

  test "should return error if request is not valid" do
    stub_configs({ 'checkdesk_base_url_private' => 'http://test.host' }) do
      get :index, name: :smooch
      assert_response 400
    end
  end

  test "should make successful request to bot" do
    stub_configs({ 'checkdesk_base_url_private' => 'http://test.host' }) do
      @request.headers['X-API-Key'] = 'test'
      get :index, name: :smooch
      assert_response :success
    end
  end

  test "should save Pender response through webhook" do
    Team.any_instance.stubs(:get_limits_keep).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    p = create_project team: t
    pm = create_project_media media: l, project: p
    pm.create_all_archive_annotations
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys

    payload = { type: 'screenshot', url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :index, name: :keep
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))
    assert_equal 'http://pender/screenshot.png', f['screenshot_url']
    Team.any_instance.unstub(:get_limits_keep)
  end

  test "should not save Pender response through webhook if link does not exist" do
    Team.any_instance.stubs(:get_limits_keep).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    p = create_project team: t
    pm = create_project_media media: l, project: p
    pm.create_all_archive_annotations
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys

    payload = { url: 'http://anothertest.com', screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :index, name: :keep
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
    f = JSON.parse(pm.get_annotations('archiver').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys
    Team.any_instance.unstub(:get_limits_keep)
  end

  test "should not save Pender response through webhook if there is no project media" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :index, name: :keep
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
  end

  test "should not save Pender response through webhook if there is no annotation" do
    Team.any_instance.stubs(:get_limits_keep).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    p = create_project team: t
    pm = create_project_media media: l, project: p
    pm.create_all_archive_annotations
    archiver = pm.get_annotations('archiver').last
    a = DynamicAnnotation::Field.where(field_name: 'pender_archive_response', annotation_id: archiver.id).last
    a.destroy

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :index, name: :keep
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
    Team.any_instance.unstub(:get_limits_keep)
  end

  test "should not save Pender response through webhook if team is not allowed" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    t = create_team
    t.set_limits_keep = false
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    p = create_project team: t
    pm = create_project_media media: l, project: p
    pm.create_all_archive_annotations

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :index, name: :keep
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
  end
end
