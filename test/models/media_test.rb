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
    create_team_user user: u, team: t, role: 'owner'
    m = create_media team: t
    pu = create_user
    pt = create_team private: true
    create_team_user user: pu, team: pt, role: 'owner'
    pm = create_media team: pt
    with_current_user_and_team(u, t) { Media.find_if_can(m.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Media.find_if_can(pm.id) }
    end
    with_current_user_and_team(pu, pt) { Media.find_if_can(pm.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { Media.find_if_can(pm.id) }
    end
  end

  test "should update and destroy media" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t

    m = nil
    with_current_user_and_team(u, t) do
      m = create_valid_media project_id: p.id
      assert_nothing_raised RuntimeError do
        m.save!
      end
    end

    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'
    with_current_user_and_team(u2, t) do
      assert_nothing_raised RuntimeError do
        m.save!
      end
      assert_raise RuntimeError do
        m.destroy!
      end
    end

    own_media = nil
    with_current_user_and_team(u2, t) do
      assert_nothing_raised RuntimeError do
        own_media = create_valid_media project_id: p.id
        own_media.save!
      end
      assert_raise RuntimeError do
        own_media.destroy!
      end
    end

    with_current_user_and_team(u, t) do
      assert_nothing_raised RuntimeError do
        RequestStore.store[:disable_es_callbacks] = true
        m.destroy!
        RequestStore.store[:disable_es_callbacks] = false
      end
    end
  end

  test "should set pender data for media" do
    t = create_team
    p = create_project team: t
    media = create_valid_media project_id: p.id
    assert_not_empty media.annotations('metadata')
  end

  test "should create version when media is created" do
    u = create_user
    create_team_user user: u
    User.current = u
    m = create_valid_media
    User.current = nil
    assert_equal 1, m.versions.size
  end

  test "should create version when media is updated" do
    u = create_user
    t = create_team
    p = create_project team: t
    create_team_user user: u, team: t, role: 'owner'
    u2 = create_user
    m = nil
    with_current_user_and_team(u, t) do
      m = create_valid_media
      create_project_media project: p, media: m
      assert_equal 1, m.versions.size
      m = m.reload
      m.user = u2
      m.save!
    end
    assert_equal 2, m.reload.versions.size
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

  test "should have projects" do
    p1 = create_project
    p2 = create_project
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    m = create_valid_media
    assert_equal [], m.project_medias
    m.project_medias << pm1
    m.project_medias << pm2
    assert_equal [p1, p2].sort, m.projects.sort
  end

  test "should set URL from Pender" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    assert_equal 'http://test.com/normalized', m.reload.url
  end

  test "should not create media if Pender returns error" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"error","data":{"message":"Error"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    assert_raises ActiveRecord::RecordInvalid do
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
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    with_current_user_and_team(u, t) do
      m = create_media project_id: p.id
      assert_equal u, m.user
    end
  end

  test "should assign to existing account" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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

  test "should not create media that is not an item" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    data = { url: url, author_url: url, type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    assert_raises ActiveRecord::RecordInvalid do
      create_media(url: url)
    end
  end

  test "should not create media with duplicated URL" do
    m = create_valid_media
    a = create_valid_account
    u = create_user
    assert_no_difference 'Media.count' do
      exception = assert_raises ActiveRecord::RecordInvalid do
        PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_url_private']) do
          WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
          create_media(url: m.url, account: a, user: u)
        end
      end
      assert_equal "Validation failed: Media with this URL exists and has id #{m.id}", exception.message
    end
  end

  test "should get media team" do
    m = create_valid_media
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, media: m
    assert_equal m.get_team, [t.id]
  end

  test "should set project" do
    p = create_project
    m = nil
    assert_difference 'ProjectMedia.count' do
      m = create_valid_media project_id: p.id
    end
    assert_equal [p], m.projects
  end

  test "should not set project" do
    m = nil
    assert_no_difference 'ProjectMedia.count' do
      m = create_valid_media
    end
    assert_equal [], m.projects
  end

  test "should get domain" do
    m = Link.new
    m.url = 'https://www.youtube.com/watch?v=b708rEG7spI'
    assert_equal 'youtube.com', m.domain
    m.url = 'localhost'
    assert_nil m.domain
    m.url = nil
    assert_nil m.domain
  end

  test "should set pender result as annotation" do
    p = create_project
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url, project_id: p.id)
    assert_equal 1, m.annotations('metadata').count
    assert_equal [m.id], m.annotations('metadata').map(&:annotated_id)
  end

  test "should handle PenderClient throwing exceptions" do
    PenderClient::Request.stubs(:get_medias).raises(StandardError)
    p = create_project
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_raise ActiveRecord::RecordInvalid do
      m = create_media(account: create_valid_account, url: url, project_id: p.id)
    end
    PenderClient::Request.unstub(:get_medias)
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    m = create_valid_media project_id: p.id
    perm_keys = ["read Link", "update Link", "create Task", "destroy Link", "create ProjectMedia", "create Comment", "create Flag", "create Tag", "create Dynamic"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(m.permissions).keys.sort }
  end

  test "should create source for Flickr media" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    p = create_project team: t
    assert_difference 'Media.count' do
      create_claim_media url: nil, project_id: p.id
    end
    assert_difference 'Media.count' do
      create_valid_media quote: nil, project_id: p.id
    end
    assert_no_difference 'Media.count' do
      assert_raise ActiveRecord::RecordInvalid do
        m = Media.new
        m.save!
      end
    end
  end

  test "should add title for claim medias" do
    p = create_project team: create_team
    m = create_claim_media quote: 'media quote'
    pm = create_project_media project: p, media: m
    assert_equal 'media quote', pm.metadata['title']
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

  test "should get media team objects" do
    m = create_valid_media
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, media: m
    assert_equal m.get_team_objects, [t]
  end

  test "should protect attributes from mass assignment" do
    raw_params = { project: create_project, user: create_user }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'picture' => 'http://twitter.com/picture/123.png' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_match /^http/, l.picture
  end

  test "should get picture for Facebook links" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'https://facebook.com/posts/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'picture' => 'http://facebook.com/images/123.png' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_match /^http/, l.picture
  end

  test "should get picture for other links that are not Facebook or Twitter (for example, Instagram and YouTube)" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'https://youtube.com/watch?v=123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'picture' => 'http://youtube.com/images/123.png' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_match /^http/, l.picture
  end

  test "should get empty picture for links without picture" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'entities' => {} } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_equal '', l.picture
  end

  test "should get text" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    time = "2017-07-10T12:10:18+03:00"
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo', 'provider' => 'twitter'} }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    c = create_claim_media
    i = create_uploaded_image
    f = create_uploaded_file
    v = create_uploaded_video
    m = Media.new
    assert_equal 'twitter', l.media_type
    assert_equal 'quote', c.media_type
    assert_equal 'uploaded image', i.media_type
    assert_equal 'uploaded file', f.media_type
    assert_equal 'uploaded video', v.media_type
    assert_equal '', m.media_type
  end

  test "should retry Pender automatically if it fails and not forced" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response1 = { 'type' => 'error', 'data' => { 'code' => 12 } }.to_json
    response2 = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response1)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response2)
    es = [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
    WebMock.disable_net_connect!(allow: es)
    l = create_link url: url
    assert_equal 'Foo', l.text
  end

  test "should get metadata from media" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'description' => 'Foo' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    assert_equal 'Foo', l.metadata['description']
  end
end
