require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AccountTest < ActiveSupport::TestCase
  def setup
    super
    @url = 'https://www.youtube.com/user/MeedanTube'
    s = create_source
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
      @account = create_account(url: @url, source: s)
    end
  end

  test "should create account" do
    assert_difference 'Account.count' do
      PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
        create_valid_account
      end
    end
  end

  test "should not save account without url" do
    account = Account.new
    assert_not account.save
  end

  test "set pender data for account" do
    assert_not_empty @account.data
  end

  test "should have user" do
    assert_kind_of User, @account.user
  end

  test "should have source" do
    assert_kind_of Source, @account.source
  end

  test "should have media" do
    m1 = create_valid_media
    m2 = create_valid_media
    @account.medias << m1
    @account.medias << m2
    assert_equal [m1, m2], @account.medias
  end

  test "should create version when account is created" do
    assert_equal 1, @account.versions.size
  end

  test "should create version when account is updated" do
    @account.user = create_user
    @account.save!
    assert_equal 2, @account.versions.size
  end

  test "should get user id from callback" do
    u = create_user email: 'test@test.com'
    @account.user = u
    @account.save!
    assert_equal u.id, @account.send(:user_id_callback, 'test@test.com')
  end

  test "should not update url when account is updated" do
    url = @account.url
    @account.url = 'http://meedan.com'
    @account.save!
    assert_not_equal @account.url, url
  end

  test "should not duplicate account url" do
    a = Account.new
    a.url = @account.url
    assert_not a.save
  end

  test "should get user from callback" do
    u = create_user email: 'test@test.com'
    a = create_valid_account
    assert_equal u.id, a.user_id_callback('test@test.com')
  end

  test "should get source from callback" do
    s = create_source name: 'test'
    a = create_valid_account
    assert_equal s.id, a.source_id_callback('test')
  end

  test "should get provider" do
    a = create_valid_account
    assert_equal 'twitter', a.provider
  end

  test "should not create source if set" do
    s = create_source
    a = nil
    assert_no_difference 'Source.count' do
      a = create_account(source: s, user_id: nil)
    end
    assert_equal s, a.reload.source
  end

  test "should create source if not set" do
    a = nil
    assert_difference 'Source.count' do
      a = create_account(source: nil, user_id: nil)
    end
    s = a.reload.source
    assert_equal 'Foo Bar', s.name
    assert_equal 'http://provider/picture.png', s.avatar
    assert_equal 'Just a test', s.slogan
  end

  test "should not create account that is not a profile" do
    assert_no_difference 'Account.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_account(data: { type: 'item' })
      end
    end
  end

  test "should not create account with duplicated URL" do
    assert_no_difference 'Account.count' do
      exception = assert_raises ActiveRecord::RecordInvalid do
        PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
          WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
          create_account(url: @url)
        end
      end
      assert_equal "Validation failed: Account with this URL exists and has source id #{@account.source_id}", exception.message
    end
  end

  test "should related accounts to team" do
    t = create_team
    a1 = create_valid_account(team: t)
    a2 = create_valid_account(team: t)
    a3 = create_valid_account
    assert_kind_of Team, a1.team
    assert_equal [a1.id, a2.id].sort, t.reload.accounts.map(&:id).sort
  end

  test "should not duplicate account url [DB validation]" do
    a1 = create_valid_account
    a2 = create_valid_account
    assert_raises ActiveRecord::RecordNotUnique do
      a2.update_attribute('url', a1.url)
    end
  end

  test "should get team" do
    t = create_team
    s = create_source
    p = create_project team: t
    create_project_source source: s, project: p
    a = create_valid_account source: s
    assert_equal [t.id], a.get_team
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: u
    a = create_valid_account
    perm_keys = ["read Account", "update Account", "destroy Account", "create Media", "create Claim", "create Link"].sort
    
    # load permissions as owner
    with_current_user_and_team(u, t) do
      assert_equal perm_keys, JSON.parse(a.permissions).keys.sort
    end
    
    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) do
      assert_equal perm_keys, JSON.parse(a.permissions).keys.sort
    end

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) do
      assert_equal perm_keys, JSON.parse(a.permissions).keys.sort
    end

    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    with_current_user_and_team(u, t) do
      assert_equal perm_keys, JSON.parse(a.permissions).keys.sort
    end
    
    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    with_current_user_and_team(u, t) do
      assert_equal perm_keys, JSON.parse(a.permissions).keys.sort
    end
    
    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) do
      assert_equal perm_keys, JSON.parse(a.permissions).keys.sort
    end
  end

end
