require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectMediasControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::ProjectMediasController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
    ProjectMedia.delete_all
    create_translation_status_stuff
    create_verification_status_stuff(false)
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
  end

  test "should not get oembed of absent media" do
    pm = create_project_media
    get :oembed, id: pm.id + 1
    assert_response 404
  end

  test "should get oembed of private media" do
    t = create_team private: true
    p = create_project team: t
    pm = create_project_media project: p
    get :oembed, id: pm.id
    assert_response :success
  end

  test "should get oembed of existing media" do
    pm = create_project_media
    get :oembed, id: pm.id
    assert_response :success
  end

  test "should allow iframe" do
    pm = create_project_media
    get :oembed, id: pm.id
    assert !@response.headers.include?('X-Frame-Options')
  end

  test "should create annotation when embedded for the first time only" do
    pm = create_project_media
    assert_equal 0, pm.get_annotations('embed_code').count
    get :oembed, id: pm.id, format: :json
    assert_equal 1, pm.reload.get_annotations('embed_code').count
    get :oembed, id: pm.id, format: :json
    assert_equal 1, pm.reload.get_annotations('embed_code').count
  end

  test "should render as HTML" do
    pm = create_project_media
    get :oembed, id: pm.id, format: :html
    assert_no_match /iframe/, @response.body
  end

  test "should render as JSON" do
    pm = create_project_media
    get :oembed, id: pm.id, format: :json
    assert_match /iframe/, @response.body
    assert_no_match /doctype/, @response.body
    assert_response :success
  end

  test "should render whole HTML instead of iframe if request comes from Pender" do
    pm = create_project_media
    @request.headers['User-Agent'] = 'Mozilla/5.0 (compatible; Pender/0.1; +https://github.com/meedan/pender)'
    get :oembed, id: pm.id, format: :json
    assert_no_match /iframe/, @response.body
    assert_match /doctype/, @response.body
    assert_response :success
    @request.headers['User-Agent'] = ''
  end

  test "should save Pender response through webhook" do
    Team.any_instance.stubs(:get_limits_keep_screenshot).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p
    f = JSON.parse(pm.get_annotations('pender_archive').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys

    payload = { type: 'screenshot', url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :webhook
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
    f = JSON.parse(pm.get_annotations('pender_archive').last.load.get_field_value('pender_archive_response'))
    assert_equal 'http://pender/screenshot.png', f['screenshot_url']
    Team.any_instance.unstub(:get_limits_keep_screenshot)
  end

  test "should not save Pender response through webhook if link does not exist" do
    Team.any_instance.stubs(:get_limits_keep_screenshot).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p
    f = JSON.parse(pm.get_annotations('pender_archive').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys

    payload = { url: 'http://anothertest.com', screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :webhook
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
    f = JSON.parse(pm.get_annotations('pender_archive').last.load.get_field_value('pender_archive_response'))
    assert_equal [], f.keys
    Team.any_instance.unstub(:get_limits_keep_screenshot)
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
    post :webhook
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
  end

  test "should not save Pender response through webhook if there is no annotation" do
    Team.any_instance.stubs(:get_limits_keep_screenshot).returns(true)
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p
    a = pm.get_annotations('pender_archive').last
    a.destroy

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :webhook
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
    Team.any_instance.unstub(:get_limits_keep_screenshot)
  end

  test "should not save Pender response through webhook if team is not allowed" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = false
    t.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p

    payload = { url: url, screenshot_taken: 1, screenshot_url: 'http://pender/screenshot.png' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :webhook
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
  end

  test "should persist parameters in embed iframe src" do
    pm = create_project_media
    pattern = /oembed\.html\?hide_notes=1/
    RequestStore.stubs(:[]).with(:request).returns(OpenStruct.new({ query_string: 'hide_notes=1', headers: { 'X-Check-Client' => 'test' } }))
    get :oembed, id: pm.id, format: :json, hide_notes: 1
    body = @response.body
    RequestStore.unstub(:[])
    assert_match pattern, body
  end
end
