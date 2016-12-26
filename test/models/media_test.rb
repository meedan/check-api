require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediaTest < ActiveSupport::TestCase
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
    assert_raise RuntimeError do
      create_valid_media team: t, current_user: u, context_team: t
    end
  end

  test "non members should not read media in private team" do
    u = create_user
    t = create_team current_user: create_user
    m = create_media team: t
    pu = create_user
    pt = create_team current_user: pu, private: true
    pm = create_media team: pt
    Media.find_if_can(m.id, u, t)
    assert_raise CheckdeskPermissions::AccessDenied do
      Media.find_if_can(pm.id, u, pt)
    end
    Media.find_if_can(pm.id, pu, pt)
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      Media.find_if_can(pm.id, pu, pt)
    end
  end

  test "should update and destroy media" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t, current_user: u
    m = create_valid_media project_id: p.id, current_user: u
    assert_nothing_raised RuntimeError do
      m.current_user = u
      m.save!
    end
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'
    assert_nothing_raised RuntimeError do
      m.current_user = u2
      m.save!
    end
    assert_raise RuntimeError do
      m.current_user = u2
      m.destroy!
    end
    own_media = create_valid_media project_id: p.id, user: u2, current_user: u2
    own_media.current_user = u2
    assert_nothing_raised RuntimeError do
      own_media.current_user = u2
      own_media.save!
    end
    assert_raise RuntimeError do
      own_media.current_user = u2
      own_media.destroy!
    end
    assert_nothing_raised RuntimeError do
      m.current_user = u
      m.destroy!
    end
  end

  test "should set pender data for media" do
    t = create_team
    p = create_project team: t
    media = create_valid_media project_id: p.id
    assert_not_empty media.project_media.data
  end

  test "should have annotations" do
    m = create_valid_media
    c1 = create_comment
    c2 = create_comment
    c3 = create_comment
    m.add_annotation(c1)
    m.add_annotation(c2)
    assert_equal [c1.id, c2.id].sort, m.reload.annotations('comment').map(&:id).sort
  end

  test "should get user id" do
    m = create_valid_media
    assert_nil m.send(:user_id_callback, 'test@test.com')
    u = create_user(email: 'test@test.com')
    assert_equal u.id, m.send(:user_id_callback, 'test@test.com')
  end

  test "should get account id" do
    m = create_valid_media
    assert_equal 2, m.account_id_callback(1, [1, 2, 3])
  end

  test "should create version when media is created" do
    m = create_valid_media
    assert_equal 2, m.versions.size
  end

  test "should create version when media is updated" do
    m = create_valid_media
    assert_equal 2, m.versions.size
    m = m.reload
    m.user = create_user
    m.save!
    assert_equal 3, m.reload.versions.size
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
    m2 = Media.new
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
    assert_equal [p1, p2], m.projects
  end

  test "should set URL from Pender" do
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    assert_equal 'http://test.com/normalized', m.reload.url
  end

  test "should not create media if Pender returns error" do
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"error","data":{"message":"Error"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
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
    m = create_media project_id: p.id, current_user: u
    assert_equal u, m.user
  end

  test "should assign to existing account" do
    pender_url = CONFIG['pender_host'] + '/api/medias'
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
    pender_url = CONFIG['pender_host'] + '/api/medias'
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
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    data = { url: url, author_url: url, type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    assert_no_difference 'Media.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_media(url: url)
      end
    end
  end

  test "should not create media with duplicated URL" do
    m = create_valid_media
    a = create_valid_account
    u = create_user
    assert_no_difference 'Media.count' do
      exception = assert_raises ActiveRecord::RecordInvalid do
        PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
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

  test "should associate with project when validation fails" do
    p1 = create_project
    p2 = create_project
    m = create_valid_media project_id: p1.id
    assert_no_difference 'Media.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_media project_id: p2.id, url: m.url
      end
    end
    assert_equal [p1, p2], m.reload.projects
  end

  test "should get domain" do
    m = Media.new
    m.url = 'https://www.youtube.com/watch?v=b708rEG7spI'
    assert_equal 'youtube.com', m.domain
    m.url = 'localhost'
    assert_nil m.domain
    m.url = nil
    assert_nil m.domain
  end

  test "should set pender result as annotation" do
    p = create_project
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url, project_id: p.id)
    assert_equal 1, m.annotations('embed').count
    assert_equal [m.id], m.annotations('embed').map(&:annotated_id)
  end

  test "should get current team" do
    m = create_media project_id: nil
    assert_nil m.current_team
    t = create_team
    p = create_project team: t
    m = create_media project_id: p.id
    assert_equal t, m.current_team
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t
    m = create_valid_media project_id: p.id
    m.context_team = t
    m.current_user = u
    perm_keys = ["read Media", "update Media", "destroy Media", "create ProjectMedia", "create Comment", "create Flag", "create Status", "create Tag"].sort
    # load permissions as owner
    assert_equal perm_keys, JSON.parse(m.permissions).keys.sort
    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    m.current_user = u.reload
    assert_equal perm_keys, JSON.parse(m.permissions).keys.sort
    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    m.current_user = u.reload
    assert_equal perm_keys, JSON.parse(m.permissions).keys.sort
    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    m.current_user = u.reload
    assert_equal perm_keys, JSON.parse(m.permissions).keys.sort
    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    m.current_user = u.reload
    assert_equal perm_keys, JSON.parse(m.permissions).keys.sort
    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    m.current_user = u.reload
    assert_equal perm_keys, JSON.parse(m.permissions).keys.sort
  end

  test "should journalist edit own status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t, user: create_user
    m = create_valid_media project_id: p.id, user: u
    m.context_team = t
    m.current_user = u
    m.project_id = p.id
    assert JSON.parse(m.permissions)['create Status']
  end

  test "should create source for Flickr media" do
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'https://www.flickr.com/photos/bees/2341623661'
    profile_url = 'https://www.flickr.com/photos/bees/'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","title":"Flickr","description":"Flickr","author_url":"https://www.flickr.com/photos/bees/"}}'
    profile_response = '{"type":"media","data":{"url":"' + url + '","type":"item","title":"Flickr","description":"Flickr","author_url":"","username":"","provider":"page"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: profile_url } }).to_return(body: profile_response)
    m = Media.new
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
    m = create_claim_media project_id: p.id, quote: 'media quote'
    d = m.project_media.data
    assert_equal 'media quote', d['title']
  end

end
