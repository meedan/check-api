require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class GreendayCollectionsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Ah::Api::Greenday::V1::CollectionsController.new
    @request.env['devise.mapping'] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
  end

  test "should return error if collection does not exist" do
    u = create_omniauth_user info: { name: 'Test User' }
    authenticate_with_user(u)
    get :show, collection_id: 0, project_id: 0
    assert_response 404
  end

  test "should update collection" do
    u = create_omniauth_user info: { name: 'Test User' }
    authenticate_with_user(u)
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t, title: 'Foo'
    assert_equal 'Foo', p.reload.title
    @request.env['RAW_POST_DATA'] = { name: 'Bar' }.to_json
    post :update, collection_id: p.id, project_id: t.id
    assert_response :success
    assert_equal 'Bar', p.reload.title
  end

  test "should show collection" do
    u = create_omniauth_user info: { name: 'Test User' }
    authenticate_with_user(u)
    t = create_team
    p = create_project team: t, title: 'Foo'
    get :show, collection_id: p.id, project_id: t.id
    assert_response :success
  end

  test "should add video to collection" do
    u = create_omniauth_user info: { name: 'Test User' }
    authenticate_with_user(u)
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t, title: 'Foo'

    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    
    url = 'https://www.youtube.com/watch?v=abc'
    data = { url: url, provider: 'youtube', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    url = 'https://www.youtube.com/watch?v=xyz'
    data = { url: url, provider: 'youtube', type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    m = create_media url: url
    create_project_media media: m, project: p

    @request.env['RAW_POST_DATA'] = { youtube_ids: ['abc', 'xyz'] }.to_json
    assert_no_difference 'ProjectMedia.count' do
      post :add_batch, collection_id: p.id, project_id: t.id
    end
    assert_response :success
  end
end 
