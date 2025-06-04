require_relative '../test_helper'

class MediaTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create media" do
    assert_difference 'Media.count' do
      create_valid_media
    end
    u = create_user
    t = create_team current_user: u
    assert_difference 'Media.count' do
      create_valid_media team: t, current_user: u
    end
  end

  test "rejected user should not create media" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t, status: 'banned'
    with_current_user_and_team(u, t) do
      assert_raise RuntimeError do
        create_valid_media team: t
      end
    end
  end

  test "non members should not read media in private team" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    m = create_media team: t
    create_project_media team: t, media: m
    pu = create_user
    pt = create_team private: true
    create_team_user user: pu, team: pt, role: 'admin'
    m2 = create_media team: pt
    create_project_media team: pt, media: m2
    with_current_user_and_team(u, t) { Media.find_if_can(m.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Media.find_if_can(m2.id) }
    end
    with_current_user_and_team(pu, pt) { Media.find_if_can(m2.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { Media.find_if_can(m2.id) }
    end
  end

  test "should update and destroy media" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    m = nil
    with_current_user_and_team(u, t) do
      m = create_valid_media team: t
      assert_nothing_raised do
        m.save!
      end
    end

    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'collaborator'
    create_project_media team: t, media: m
    with_current_user_and_team(u2, t) do
      assert_nothing_raised do
        m.reload.save!
      end
      assert_raise RuntimeError do
        m.destroy!
      end
    end

    own_media = nil
    with_current_user_and_team(u2, t) do
      assert_nothing_raised do
        own_media = create_valid_media team: t
        own_media.save!
      end
      assert_raise RuntimeError do
        own_media.destroy!
      end
    end

    # TODO: review destroy permissions for Media
    # with_current_user_and_team(u, t) do
    #   assert_nothing_raised do
    #     RequestStore.store[:disable_es_callbacks] = true
    #     m.destroy!
    #     RequestStore.store[:disable_es_callbacks] = false
    #   end
    # end
  end

  test "should set pender data for media" do
    t = create_team
    media = create_valid_media team: t
    assert_not_empty media.annotations('metadata')
  end

  test "should not update url when media is updated" do
    m = create_valid_media
    m = m.reload
    url = m.url
    m.url = 'http://meedan.com'
    m.save
    assert_not_equal m.url, url
  end

  test "should not duplicate media url" do
    m = create_valid_media
    m2 = Link.new
    m2.url = m.url
    assert_not m2.save
  end

  test "should have project medias" do
    pm1 = create_project_media
    pm2 = create_project_media
    m = create_valid_media
    assert_equal [], m.project_medias
    m.project_medias << pm1
    m.project_medias << pm2
    assert_equal [pm1, pm2], m.project_medias
  end

  test "should set URL from Pender" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    assert_equal 'http://test.com/normalized', m.reload.url
  end

  test "should not create media if Pender returns error" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"error","data":{"message":"Error"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    assert_raises RuntimeError do
      create_media(account: create_valid_account, url: url)
    end
  end

  test "should not duplicate media url [DB validation]" do
    m1 = create_valid_media
    m2 = create_valid_media
    assert_raises ActiveRecord::RecordNotUnique do
      m2.update_attribute('url', m1.url)
    end
  end

  test "should set user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      m = create_media team: t
      assert_equal u, m.user
    end
  end

  test "should assign to existing account" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    media_url = 'http://www.facebook.com/meedan/posts/123456'
    author_url = 'http://facebook.com/123456'
    author_normal_url = 'http://www.facebook.com/meedan'

    data = { url: media_url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media_url } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_normal_url } }).to_return(body: response)

    m = nil

    a = create_account url: author_normal_url

    assert_no_difference 'Account.count' do
      m = create_media url: media_url, account_id: nil, user_id: nil, account: nil, user: nil
    end

    assert_equal a, m.reload.account
  end

  test "should assign to newly created account" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    media_url = 'http://www.facebook.com/meedan/posts/123456'
    author_url = 'http://facebook.com/123456'
    author_normal_url = 'http://www.facebook.com/meedan'

    data = { url: media_url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media_url } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_normal_url } }).to_return(body: response)

    m = nil

    assert_difference 'Account.count' do
      m = create_media url: media_url, account_id: nil, user_id: nil, account: nil, user: nil
    end

    assert_equal author_normal_url, m.reload.account.url
  end

  test "should not create media with duplicated URL" do
    m = create_valid_media
    a = create_valid_account
    u = create_user
    assert_no_difference 'Media.count' do
      exception = assert_raises ActiveRecord::RecordInvalid do
        PenderClient::Mock.mock_medias_returns_parsed_data(CheckConfig.get('pender_url_private')) do
          WebMock.disable_net_connect! allow: [CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s]
          create_media(url: m.url, account: a, user: u)
        end
      end
      assert_equal "Media with this URL exists and has id #{m.id}", exception.message
    end
  end

  test "should get media team" do
    m = create_valid_media
    t = create_team
    pm = create_project_media team: t, media: m
    assert_equal m.team_ids, [t.id]
  end

  test "should get domain" do
    m = Link.new
    m.url = 'https://www.youtube.com/watch?v=b708rEG7spI'
    assert_equal 'youtube.com', m.domain
    m.url = 'localhost'
    assert_nil m.domain
    m.url = nil
    assert_nil m.domain
    # get domain for other types
    m = create_claim_media
    assert_empty m.domain
  end

  test "should set pender result as annotation" do
    t = create_team
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url, team: t)
    assert_equal 1, m.annotations('metadata').count
    assert_equal [m.id], m.annotations('metadata').map(&:annotated_id)
  end

  test "should handle PenderClient throwing exceptions" do
    PenderClient::Request.stubs(:get_medias).raises(StandardError)
    t = create_team
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_raise ActiveRecord::RecordInvalid do
      m = create_media(account: create_valid_account, url: url, team: t)
    end
    PenderClient::Request.unstub(:get_medias)
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    m = create_valid_media team: t
    perm_keys = ["read Link", "update Link", "create Task", "destroy Link", "create ProjectMedia", "create Tag", "create Dynamic"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as collaborator
    tu = u.team_users.last; tu.role = 'collaborator'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }
  end

  test "should create source for Flickr media" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://www.flickr.com/photos/bees/2341623661'
    profile_url = 'https://www.flickr.com/photos/bees/'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","title":"Flickr","description":"Flickr","author_url":"https://www.flickr.com/photos/bees/"}}'
    profile_response = '{"type":"media","data":{"url":"' + url + '","type":"item","title":"Flickr","description":"Flickr","author_url":"","username":"","provider":"page"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: profile_url } }).to_return(body: profile_response)
    m = Link.new
    m.url = url
    m.save!
    assert_not_nil m.account.source
  end

  test "should add quote or url for media creations" do
    t = create_team
    assert_difference 'Media.count' do
      create_claim_media url: nil, team: t
    end
    assert_difference 'Media.count' do
      create_valid_media quote: nil, team: t
    end
    assert_no_difference 'Media.count' do
      assert_raise ActiveRecord::RecordInvalid do
        m = Media.new
        m.save!
      end
    end
  end

  test "should add title for claim medias" do
    t = create_team
    m = create_claim_media quote: 'media quote'
    pm = create_project_media team: t, media: m
    assert_equal 'media quote', pm.title
  end

  test "should get class from input" do
    assert_equal 'Link', Media.class_from_input(url: 'something')
    assert_equal 'Claim', Media.class_from_input(quote: 'something')
    assert_nil Media.class_from_input({})
  end

  test "should get image paths" do
    l = create_link
    assert_equal '', l.embed_path
    assert_equal '', l.thumbnail_path
    c = create_claim_media
    assert_equal '', c.embed_path
    assert_equal '', c.thumbnail_path
    i = create_uploaded_image
    assert_match /png$/, i.embed_path
    assert_match /png$/, i.thumbnail_path
  end

  test "should protect attributes from mass assignment" do
    raw_params = { team: create_team, user: create_user }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActionController::UnfilteredParameters do
      Media.create(params)
    end
  end

  test "should get empty picture for claims" do
    c = create_claim_media
    assert_equal '', c.picture
  end

  test "should get picture for uploaded images" do
    i = create_uploaded_image
    assert_match /^http/, i.picture
  end

  test "should get picture for Twitter links" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'picture' => 'http://twitter.com/picture/123.png' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_match /^http/, l.picture
  end

  test "should get picture for Facebook links" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://facebook.com/posts/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'picture' => 'http://facebook.com/images/123.png' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_match /^http/, l.picture
  end

  test "should get picture for other links that are not Facebook or Twitter (for example, Instagram and YouTube)" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://youtube.com/watch?v=123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'picture' => 'http://youtube.com/images/123.png' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_match /^http/, l.picture
  end

  test "should get empty picture for links without picture" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'entities' => {} } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_equal '', l.picture
  end

  test "should get text" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    c = create_claim_media quote: 'Bar'
    i = create_uploaded_image
    assert_equal 'Foo', l.text
    assert_equal 'Bar', c.text
    assert_equal '', i.text
  end

  test "should get domain from url with arabic chars" do
    m = create_valid_media
    m.stubs(:url).returns("http://www.youm7.com/story/2017/11/27/مستشفى-ألمانى-يعلن-نجاح-جراحة-بالعمود-الفقرى-للبابا-تواضروس/3529785")
    assert_nothing_raised do
      assert_equal 'youm7.com', m.domain
    end
  end

  test "should get original published time" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    time = "2017-07-10T12:10:18+03:00"
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo', 'published_at' => time} }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    c = create_claim_media
    i = create_uploaded_image
    assert_equal Time.at(time.to_time.to_i), l.original_published_time
    assert_equal '', c.original_published_time
    assert_equal '', i.original_published_time
  end

  test "should get original published time for times in all formats" do
    l = create_media
    time = "2017-07-10T12:10:18+03:00"
    [time.to_time.to_i, time].each do |t|
      l.stubs(:metadata).returns({'published_at' => t })
      assert_equal Time.at(time.to_time.to_i), l.original_published_time
      l.unstub(:metadata)
    end
  end

  test "should get media type" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    time = "2017-07-10T12:10:18+03:00"
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo', 'provider' => 'twitter'} }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    c = create_claim_media
    i = create_uploaded_image
    f = create_uploaded_file
    v = create_uploaded_video
    a = create_uploaded_audio
    m = Media.new
    assert_equal 'twitter', l.media_type
    assert_equal 'quote', c.media_type
    assert_equal 'uploaded image', i.media_type
    assert_equal 'uploaded file', f.media_type
    assert_equal 'uploaded video', v.media_type
    assert_equal 'uploaded audio', a.media_type
    assert_equal '', m.media_type
  end

  test "should retry Pender automatically if it fails and not forced" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response1 = { 'type' => 'error', 'data' => { 'code' => 12 } }.to_json
    response2 = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response1)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response2)
    es = [CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s]
    WebMock.disable_net_connect!(allow: es)
    l = create_link url: url
    assert_equal 'Foo', l.text
  end

  test "should get metadata from media" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_equal 'Foo', l.metadata['description']
    assert_not_equal({}, l.get_saved_pender_data)
    assert_not_equal({}, l.metadata)
    l.annotations.delete_all
    assert_equal({}, l.get_saved_pender_data)
    assert_equal({}, l.metadata)
  end

  test "should send specific token to parse url on pender" do
    params1 = { url: random_url }
    params2 = { url: random_url }
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), params1, CheckConfig.get('pender_key'), nil).returns({"type" => "media","data" => {"url" => params1[:url], "type" => "item", "title" => "Default token"}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), params2, 'specific_token', nil).returns({"type" => "media","data" => {"url" => params2[:url], "type" => "item", "title" => "Specific token"}})

    l = Link.new url: params1[:url]
    l.valid?
    l.save!
    assert_equal 'Default token', Link.find(l.id).metadata['title']

    l = Link.new url: params2[:url], pender_key: 'specific_token'
    l.valid?
    l.save!
    assert_equal 'Specific token', Link.find(l.id).metadata['title']
    PenderClient::Request.unstub(:get_medias)
  end

  test "should use normalized URL from Pender" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url1 = random_url
    url2 = random_url
    response = { 'type' => 'media', 'data' => { 'url' => url2, 'type' => 'item', 'description' => 'Foo' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url1 } }).to_return(body: response)
    l = create_link url: url1
    assert_equal url2, l.reload.url
  end

  test "should create blank media" do
    assert_difference 'Blank.count', 2 do
      2.times do
        m = create_blank_media
        assert_equal 'blank', m.media_type
        assert_equal 'Blank', m.class_name
      end
    end
  end

  test "should not create blank media if there is content" do
    assert_raises ActiveRecord::RecordInvalid do
      Blank.create! quote: random_string
    end
    assert_raises ActiveRecord::RecordInvalid do
      Blank.create! url: random_url
    end
    assert_raises ActiveRecord::RecordInvalid do
      Blank.create! file: random_string
    end
  end

  test "should keep original URL if Pender doesn't return a normalized one" do
    url = random_url
    assert_equal url, Link.new(url: url).get_url_from_result(nil)
  end

  test "get filename of an uploaded file" do
    uploaded_video = ActionDispatch::Http::UploadedFile.new({
      :filename => 'rails.mp4',
      :type => 'video/mp4',
      :tempfile => File.new(File.join(Rails.root, 'test', 'data', 'rails.mp4'))
    })
    assert_equal 'a3ac7ddabb263c2d00b73e8177d15c8d.mp4', Media.filename(uploaded_video)
  end

  test "should return empty string if there is no picture" do
    Link.any_instance.stubs(:get_saved_pender_data).returns([])
    l = create_valid_media
    assert_equal '', l.picture
  end

  test "should sanitize link data before storing" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = random_url
    response = { type: 'media', data: { url: url, type: 'item', title: "Foo \u0000 bar" } }
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response.to_json)
    assert_difference 'Link.count' do
      create_media url: url
    end
  end

  test 'should validate url length' do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = "#{random_url}?params=#{random_string(2000)}"
    response = { type: 'media', data: { url: url, type: 'item', title: "Foo \u0000 bar" } }
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response.to_json)
    assert_no_difference 'Link.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_media url: url
      end
    end
  end

  test "should have uuid" do
    m = create_media
    assert_equal m.id, m.uuid
    c1 = create_claim_media quote: 'Foo'
    assert_equal c1.id, c1.uuid
    create_project_media media: c1
    assert_equal c1.id, c1.uuid
    c2 = create_claim_media quote: 'Foo'
    create_project_media media: c2
    assert_equal c1.id, c2.uuid
  end

  test "Claim Media: should save the original_claim and original_claim_hash when created from original claim" do
    claim = 'This is a claim.'
    claim_media = Media.find_or_create_claim_media(claim,  { has_original_claim: true })

    assert_not_nil claim_media.original_claim_hash
    assert_not_nil claim_media.original_claim
    assert_equal claim, claim_media.original_claim
  end

  test "Claim Media: should not save original_claim and original_claim_hash when not created from original claim" do
    claim_media = Claim.create!(quote: 'This is a claim.')
    assert_nil claim_media.original_claim_hash
    assert_nil claim_media.original_claim
  end

  test "Claim Media: should not create duplicate media if media with original_claim_hash exists" do
    assert_difference 'Claim.count', 1 do
      2.times { Media.find_or_create_claim_media('This is a claim.', { has_original_claim: true }) }
    end
  end

  test "Link Media: should save the original_claim and original_claim_hash when created from original claim" do
    team = create_team

    # Mock Pender response for Link
    link_url = 'https://example.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    link_response = {
      type: 'media',
      data: {
        url: link_url,
        type: 'item'
      }
    }.to_json
    WebMock.stub_request(:get, pender_url).with(query: { url: link_url }).to_return(body: link_response)

    link_media = Media.find_or_create_link_media(link_url, { team: team, has_original_claim: true })

    assert_not_nil link_media.original_claim_hash
    assert_not_nil link_media.original_claim
    assert_equal link_url, link_media.original_claim
  end

  test "Link Media: should not save original_claim and original_claim_hash when not created from original claim" do
    # Mock Pender response for Link
    link_url = 'https://example.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    link_response = {
      type: 'media',
      data: {
        url: link_url,
        type: 'item'
      }
    }.to_json
    WebMock.stub_request(:get, pender_url).with(query: { url: link_url }).to_return(body: link_response)

    link_media = Link.create!(url: link_url)

    assert_nil link_media.original_claim_hash
    assert_nil link_media.original_claim
  end

  test "Link Media: should not create duplicate media if media with original_claim_hash exists" do
    team = create_team

    # Mock Pender response for Link
    link_url = 'https://example.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    link_response = {
      type: 'media',
      data: {
        url: link_url,
        type: 'item'
      }
    }.to_json
    WebMock.stub_request(:get, pender_url).with(query: { url: link_url }).to_return(body: link_response)

    assert_difference 'Link.count', 1 do
      2.times { Media.find_or_create_link_media(link_url, { team: team, has_original_claim: true }) }
    end
  end

  test "Uploaded Media: should save the original_claim and original_claim_hash when created from original claim" do
    Tempfile.create(['test_audio', '.mp3']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      file.rewind
      audio_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, audio_url).to_return(body: file.read, headers: { 'Content-Type' => 'audio/mp3' })
      downloaded_file = Media.downloaded_file(audio_url)

      uploaded_media = Media.find_or_create_uploaded_file_media(downloaded_file, 'UploadedAudio', { has_original_claim: true, original_claim_url: audio_url })

      assert_not_nil uploaded_media.original_claim_hash
      assert_not_nil uploaded_media.original_claim
      assert_equal audio_url, uploaded_media.original_claim
    end
  end

  test "Uploaded Media: should not save original_claim and original_claim_hash when not created from original claim" do
    uploaded_media = create_uploaded_audio

    assert_nil uploaded_media.original_claim_hash
    assert_nil uploaded_media.original_claim
  end

  test "Uploaded Media: should not create duplicate media if media with original_claim_hash exists" do
    Tempfile.create(['test_audio', '.mp3']) do |file|
      file.write(File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      file.rewind
      audio_url = "http://example.com/#{file.path.split('/').last}"
      WebMock.stub_request(:get, audio_url).to_return(body: file.read, headers: { 'Content-Type' => 'audio/mp3' })
      downloaded_file = Media.downloaded_file(audio_url)

      assert_difference 'UploadedAudio.count', 1 do
        2.times { Media.find_or_create_uploaded_file_media(downloaded_file, 'UploadedAudio', { has_original_claim: true, original_claim_url: audio_url }) }
      end
    end
  end
end
