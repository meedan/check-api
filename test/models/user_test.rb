require_relative '../test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create user" do
    assert_difference 'User.count' do
      create_user
    end
  end

  test "should have user name" do
    assert_no_difference 'User.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_user name: nil
      end
    end
  end

  test "should update and destroy user" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    u2 = create_user
    create_team_user team: t, user: u2, role: 'editor'
    u2.save!

    with_current_user_and_team(u2, t) do
      assert_raise RuntimeError do
        User.find(u.id).save!
      end
      assert_raise RuntimeError do
        User.find(u.id).save!
      end
    end

    with_current_user_and_team(u, t) do
     assert_raise RuntimeError do
        User.find(u2.id).destroy
      end
    end
  end

  test "non members should not read users in private team" do
    u = create_user
    t = create_team
    u1 = create_user
    create_team_user user: u1, team: t
    pu = create_user
    pt = create_team private: true
    ptu = create_team_user user: pu, team: pt
    u2 = create_user
    create_team_user user: u2, team: pt
    with_current_user_and_team(u, t) { User.find_if_can(u1.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { User.find_if_can(u2.id) }
    end
    with_current_user_and_team(pu, pt) do
      User.find_if_can(u2.id)
      User.find_if_can(u1.id)
    end
    with_current_user_and_team(u, t) { User.find_if_can(u.id) }
    ptu.status = 'requested'; ptu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { User.find_if_can(u2.id) }
    end
  end

  test "should not require password if there is a provider" do
    assert_nothing_raised do
      create_omniauth_user password: '', provider: 'twitter'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_user password: ''
    end
  end

  test "should not require email for omniauth user" do
    u = nil
    assert_nothing_raised do
      u = create_omniauth_user email: ''
    end
    assert_equal '', u.reload.email
  end

  test "should output json" do
    u = create_user
    assert_nothing_raised do
      JSON.parse(u.to_json)
    end
  end

  test "should have token" do
    assert_kind_of String, User.token('foo', '123', 'bar', 'test')
  end

  test "should decript token" do
    token = User.token('foo', '123', 'bar', 'test')
    info = User.from_token(token)
    exp = {
      'provider' => 'foo',
      'id' => '123',
      'token' => 'bar',
      'secret' => 'test'
    }
    assert_equal exp, info
  end

  test "should create source when user is created" do
    u = nil
    assert_difference 'Source.count' do
      u = create_user
    end
    s = create_source user: u
    u = u.reload
    assert_equal u.source_id, u.source.id
  end

  test "should not create account if user has no url" do
    assert_no_difference 'Account.count' do
      create_omniauth_user url: nil, provider: 'facebook', omniauth_info: {'url' => ''}
    end
  end

  test "should not create account if user has no provider" do
    assert_no_difference 'Account.count' do
      create_omniauth_user provider: '', url: 'http://meedan.com'
    end
  end

  test "should create account if user has provider and url" do
    assert_difference 'Account.count' do
      PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_url_private']) do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
        create_omniauth_user provider: 'youtube', url: 'https://www.youtube.com/user/MeedanTube'
      end
    end
  end

  test "should set token if blank" do
    u = create_user token: ''
    assert_not_equal '', u.reload.token
  end

  test "should not set token if not blank" do
    u = create_user token: 'test'
    assert_equal 'test', u.reload.token
  end

  test "should not set login if not blank" do
    u = create_user login: 'test'
    assert_equal 'test', u.reload.login
  end

  test "should set login from name" do
    info = {login: '', nickname: '', name: 'Foo Bar'}
    u = create_omniauth_user provider: 'facebook', info: info, email: ''
    assert_equal 'foo-bar', u.reload.login
  end

  test "should set login from email" do
    u = create_user login: '', name: 'Foo Bar', email: 'foobar@test.com'
    assert_equal 'foobar', u.reload.login
  end

  test "should send welcome email when user is created" do
    stub_config 'send_welcome_email_on_registration', true do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        create_user skip_confirmation: true
      end
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        create_omniauth_user provider: 'twitter', password: nil
        create_omniauth_user provider: 'facebook', password: nil
      end
    end

    stub_config 'send_welcome_email_on_registration', false do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        create_user skip_confirmation: true
        create_omniauth_user provider: 'twitter'
        create_omniauth_user provider: 'facebook'
      end
    end
  end

  test "should send email when user email is duplicate" do
    u = create_omniauth_user provider: 'facebook'
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_raises ActiveRecord::RecordInvalid do
        create_user email: u.email
      end
    end
  end

  test "should not add duplicate mail" do
    u = create_user
    create_account user: u, source: u.source, provider: 'slack', email: 'test@local.com'
    assert_no_difference 'User.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_user email: u.email
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_user email: 'test@local.com'
      end
    end
  end

  test "should not register with banned email" do
    u = create_user is_active: false
    assert_no_difference 'User.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_user email: u.email
      end
    end
    # should not send duplicate mail
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_raises ActiveRecord::RecordInvalid do
        create_user email: u.email
      end
    end
  end

  test "should update user mail" do
    u = create_user
    u2 = create_user
    assert_nothing_raised do
      u.email = 'test_01@local.com'; u.save!
    end
    assert_raises ActiveRecord::RecordInvalid do
      u.email = u2.email; u.save!
    end
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_raises ActiveRecord::RecordInvalid do
        u.email = u2.email; u.save!
      end
    end
  end

  test "should have projects" do
    p1 = create_project
    p2 = create_project
    u = create_user
    u.projects << p1
    u.projects << p2
    assert_equal [p1, p2].sort, u.projects.sort
  end

  test "should not upload an image that is not an image" do
    assert_no_difference 'User.count' do
      assert_raises MiniMagick::Invalid do
        create_user image: 'not-an-image.txt', profile_image: nil
      end
    end
  end

  test "should not upload a big logo" do
    assert_no_difference 'User.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_user image: 'ruby-big.png', profile_image: nil
      end
    end
  end

  test "should not upload a small logo" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_user image: 'ruby-small.png'
      end
    end
  end

  test "should have a default uploaded image" do
    u = create_user image: nil
    assert_match /user\.png$/, u.profile_image
  end

  test "should get user role" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'owner'
    Team.stubs(:current).returns(t)
    assert_equal u.role, 'owner'
    Team.unstub(:current)
  end

  test "verify user role" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    Team.stubs(:current).returns(t)
    assert u.role? :editor
    assert u.role? :journalist
    assert_not u.role? :owner
    Team.unstub(:current)
  end

  test "should set current team with one of users team" do
    u = create_user
    t = create_team
    u.teams << t; u.save!
    u.current_team_id = t.id; u.save!
    assert_equal u.current_team_id, t.id
    t2 = create_team
    u.current_team_id = t2.id
    u.save!
    assert_nil u.reload.current_team_id
    t3 = create_team
    create_team_user team: t3, user: u, status: 'requested'
    u.current_team_id = t3.id
    u.save!
    assert_nil u.reload.current_team_id
  end

  test "should set and retrieve current team" do
    u = create_user
    assert_nil u.current_team
    t = create_team
    t2 = create_team
    u.teams << t; u.save!
    u.teams << t2; u.save!
    # test fallback for current team
    assert_equal t2, u.current_team
    u.current_team_id = t.id
    u.save!
    assert_equal t, u.current_team
  end

  test "should get user teams" do
     u = create_user
     t1 = create_team
     create_team_user team: t1, user: u
     t2 = create_team
     create_team_user team: t2, user: u, status: 'requested'
     assert_equal [t1.slug, t2.slug].sort, JSON.parse(u.user_teams).keys.sort
  end

  test "should not crash if account is not created" do
    assert_nothing_raised do
      assert_difference 'User.count' do
        assert_difference 'Source.count' do
          create_user name: 'Test', url: 'http://test.com'
        end
      end
    end
  end

  test "should return whether a user is member of a team" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user team: t1, user: u
    assert u.is_member_of?(t1)
    assert !u.is_member_of?(t2)
  end

  test "should have settings" do
    u = create_user
    assert_equal({}, u.settings)
    assert_nil u.setting(:foo)
    u.set_foo = 'bar'
    u.save!
    assert_equal 'bar', u.reload.setting(:foo)

    assert_raise NoMethodError do
      u.something
    end
  end

  test "should not crash when creating user account" do
    Account.any_instance.stubs(:save).raises(Errno::ECONNREFUSED)
    assert_nothing_raised do
      create_omniauth_user url: 'http://twitter.com/meedan', provider: 'twitter'
    end
    Account.any_instance.unstub(:save)
  end

  test "should edit own profile" do
    u = create_user
    u2 = create_user
    t = create_team
    s = u.source
    assert_nil s.team
    # should edit own profile even user has no team
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        s.name = 'update name'; s.save!
        assert_equal s.reload.name, 'update name'
      end
    end
    create_team_user user: u, team: t, role: 'contributor'
    # should edit own profile
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        s.name = 'update name'; s.save!
        assert_equal s.reload.name, 'update name'
      end
      # should remove accounts from own profile
      a = create_account
      as = create_account_source account: a, source: s
      as.destroy
    end
    User.current = Team.current = nil
    # other roles should not edit user profile
    create_team_user user: u2, team: t, role: 'journalist'
    js = u2.source
    with_current_user_and_team(u2, t) do
      assert_raise RuntimeError do
        s.save!
      end
      # check that journliast has a permission to update his profile
      js.name = 'update name'; js.save!
      assert_equal js.reload.name, 'update name'
    end

  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    user = create_user
    perm_keys = ["read User", "update User", "destroy User", "create Source", "create TeamUser", "create Team", "create Project"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(user.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(user.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(user.permissions).keys.sort }

    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(user.permissions).keys.sort }

    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(user.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(user.permissions).keys.sort }
  end

  test "should get handle" do
    u = create_user email: 'user@email.com'
    assert_equal 'user@email.com', u.handle
    u = create_omniauth_user provider: 'facebook', email: '', url: 'https://facebook.com/10157109339765023'
    assert_equal 'https://facebook.com/10157109339765023', u.handle
  end

  test "should get handle for Slack" do
    u = create_omniauth_user provider: 'slack', email: '', info: { name: 'caiosba' }, extra: { 'raw_info' => { 'url' => 'https://meedan.slack.com' } }
    assert_equal 'caiosba at https://meedan.slack.com', u.handle
  end

  test "should return whether two users are colleagues in a team" do
    u1 = create_user
    u2 = create_user
    t1 = create_team
    t2 = create_team
    t3 = create_team
    create_team_user team: t1, user: u1
    create_team_user team: t2, user: u2
    create_team_user team: t3, user: u1
    assert !u1.is_a_colleague_of?(u2)
    assert !u2.is_a_colleague_of?(u1)
    create_team_user team: t3, user: u2
    assert u1.is_a_colleague_of?(u2)
    assert u2.is_a_colleague_of?(u1)
  end

  test "should require confirmation for e-mail accounts only" do
    u = create_omniauth_user provider: 'twitter'
    assert !u.send(:confirmation_required?)
    u = create_user confirm: false
    assert u.send(:confirmation_required?)
  end

  test "should require confirmation after update email" do
    u = create_omniauth_user provider: 'twitter'
    assert u.is_confirmed?
    u = create_user email: 'foo@bar.com', confirm: false
    assert_not u.is_confirmed?
    u.skip_check_ability = true
    u.confirm
    assert u.is_confirmed?
    u.email = 'foo+test@bar.com';u.save!
    assert_not u.is_confirmed?
  end

  test "should set user password" do
    u = create_user password: '12345678', password_confirmation: '12345678'
    u.set_password = '87654321'
    u.save!
    assert_equal '87654321', u.password
    assert_equal '87654321', u.password_confirmation
  end

  test "should not change user password if value is blank" do
    u = create_user password: '12345678', password_confirmation: '12345678'
    u.set_password = ''
    u.save!
    assert_equal '12345678', u.password
    assert_equal '12345678', u.password_confirmation
  end

  test "should protect attributes from mass assignment" do
    raw_params = { name: 'My name', login: 'my-name' }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      User.create(params)
    end
  end

  test "should delay confirmation email" do
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    u = create_user
    assert_equal 0, u.send(:pending_notifications).size
    Sidekiq::Extensions::DelayedMailer.jobs.clear
    assert_equal 0, Sidekiq::Extensions::DelayedMailer.jobs.size
    u.password = '12345678'
    u.password_confirmation = '12345678'
    u.send(:send_devise_notification, 'confirmation_instructions', 'token', {})
    u.save!
    assert_equal 1, Sidekiq::Extensions::DelayedMailer.jobs.size
    assert_equal 1, u.send(:pending_notifications).size
    u = User.last
    u.send(:send_devise_notification, 'confirmation_instructions', 'token', {})
    assert_equal 2, Sidekiq::Extensions::DelayedMailer.jobs.size
    assert_equal 0, u.send(:pending_notifications).size
  end

  test "should get annotations from user" do
    u = create_user
    c = create_comment annotator: u
    create_comment
    d = create_dynamic_annotation annotator: u
    assert_equal [d, c], u.annotations.to_a
    assert_equal [c], u.annotations('comment').to_a
  end

  test "should have JSON settings" do
    assert_kind_of String, create_user.jsonsettings
  end

  test "should update Facebook id" do
    u = create_omniauth_user provider: 'facebook', uid: '123456', email: 'user@fb.com'
    a = u.get_social_accounts_for_login({provider: 'facebook', uid: '123456'}).first
    assert_equal '123456', a.uid
    User.update_facebook_uuid(OpenStruct.new({ provider: 'facebook', url: a.url, uid: '654321', info: OpenStruct.new({ email: 'user@fb.com' })}))
    assert_equal '654321', a.reload.uid
  end

  test "should not update Facebook id if email not set" do
    u1 = create_omniauth_user provider: 'facebook', uid: '123456', email: ''
    u2 = create_omniauth_user provider: 'facebook', uid: '456789', email: ''
    a1 = u1.get_social_accounts_for_login({provider: 'facebook', uid: '123456'}).first
    a2 = u2.get_social_accounts_for_login({provider: 'facebook', uid: '456789'}).first
    assert_equal '123456', a1.uid
    assert_equal '456789', a2.uid
    User.update_facebook_uuid(OpenStruct.new({ provider: 'facebook',url: a1.url, uid: '456789', info: OpenStruct.new({ email: '' })}))
    assert_equal '123456', a1.reload.uid
    assert_equal '456789', a2.reload.uid
  end

  test "should save valid languages" do
    u = create_user
    value = ["en"]
    assert_nothing_raised do
      u.set_languages(value)
      u.save!
    end
  end

  test "should not save languages if is not valid" do
    u = create_user
    variations = [
      'invalid_language',
      10
    ]
    variations.each do |value|
      assert_raises ActiveRecord::RecordInvalid do
        u.set_languages(value)
        u.save!
      end
    end
  end

  test "should not have User type" do
    u = create_user
    assert_nil u.type
  end

  test "should not have API key" do
    a = create_api_key
    assert_raises ActiveRecord::RecordInvalid do
      create_user api_key_id: a.id
    end
    assert_nothing_raised do
      create_user api_key_id: nil
    end
  end

  test "should have number of teams" do
    u = create_user
    create_team_user user: u
    create_team_user user: u
    assert_equal 2, u.reload.number_of_teams
  end

  test "should update account url when update Facebook id" do
    WebMock.disable_net_connect!
    url1 = 'https://www.facebook.com/1062518227129764'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url1 } }).to_return(body: '{"type":"media","data":{"url":"' + url1 + '","type":"profile"}}')

    u = create_omniauth_user provider: 'facebook', uid: '1062518227129764', email: 'user@fb.com', url: url1
    account = u.get_social_accounts_for_login({provider: 'facebook', uid: '1062518227129764'}).first
    assert_equal '1062518227129764', account.uid

    assert_equal url1, account.url

    url2 = 'https://www.facebook.com/100001147915899'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: '{"type":"media","data":{"url":"' + url2 + '/","type":"profile"}}')
    User.update_facebook_uuid(OpenStruct.new({ provider: 'facebook', uid: '100001147915899', info: OpenStruct.new({ email: 'user@fb.com' }), url: url2}))
    assert_equal '100001147915899', account.reload.uid
    assert_equal url2, account.reload.url
    WebMock.allow_net_connect!
  end

  test "should create user when account cannot be saved" do
    url = 'https://www.facebook.com/1062518227129764'
    credentials = OpenStruct.new({ token: '1234', secret: 'secret'})
    info = OpenStruct.new({ email: 'user@fb.com', name: 'John', image: 'picture.png' })
    auth = OpenStruct.new({ url: url, provider: 'facebook', uid: '1062518227129764', credentials: credentials, info: info})
    Account.any_instance.stubs(:save).returns(false)
    assert_difference 'User.count' do
      User.from_omniauth(auth)
    end
    u = User.find_by_email 'user@fb.com'
    assert u.accounts.empty?
    Account.any_instance.unstub(:save)
  end

  test "should set email notifications settings" do
    u = create_user
    u.send_email_notifications = true
    u.send_successful_login_notifications = true
    u.send_failed_login_notifications = true
    u.save!
    assert u.get_send_email_notifications
    assert u.get_send_successful_login_notifications
    assert u.get_send_successful_login_notifications
  end

  test "should destroy related items" do
    u = create_user
    t = create_team
    t2 = create_team
    id = u.id
    create_team_user user: u, team: t
    create_team_user user: u, team: t2
    u.destroy
    assert_equal 0, TeamUser.where(user_id: id).count
  end

  test "should create account with omniauth data" do
    info = {
      "nickname"=>"daniela", "team"=>"meedan", "user"=>"daniela", "name"=>"daniela feitosa", "description"=>"",
      "image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"
    }
    url = "https://meedan.slack.com/team/daniela"
    u = create_omniauth_user provider: 'slack', info: info, url: url
    account = u.get_social_accounts_for_login({provider: 'slack'}).first
    assert account.created_on_registration?
    assert_equal url, account.url
    assert_equal info['nickname'], account.data['username']
    assert_equal info['name'], account.data['author_name']
    assert_equal info['description'], account.data['description']
    assert_equal info['image'], account.data['picture']
    assert_equal url, account.data['url']
  end

  test "should create source with image on omniauth data" do
    info = { "image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"}

    u = create_omniauth_user provider: 'slack', info: info
    account = u.get_social_accounts_for_login({provider: 'slack'}).first
    source = u.source
    assert_equal info['image'], source.avatar
  end

  test "should create source with default image" do
    u = create_user
    source = u.source
    assert_match /images\/user.png/, source.avatar
  end

  test "should set source image when call user from omniauth" do
    u = create_omniauth_user provider: 'twitter', uid: '12345'
    assert_match /images\/user.png/, u.source.avatar
    credentials = OpenStruct.new({ token: '1234', secret: 'secret'})
    info = OpenStruct.new({ email: 'user@fb.com', name: 'John', image: 'picture.png' })
    auth = OpenStruct.new({ provider: 'twitter', uid: '12345', credentials: credentials, info: info, url: random_url})
    omniauth_info = {"info"=> { "image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"} }
    Account.any_instance.stubs(:omniauth_info).returns(omniauth_info)
    User.from_omniauth(auth)
    assert_equal omniauth_info['info']['image'], User.find(u.id).source.avatar
    assert_equal omniauth_info['info']['image'], User.find(u.id).source.image
    Account.any_instance.unstub(:omniauth_info)
  end

  test "should set user image as source image and return the uploaded image instead of omniauth" do
    u = create_user image: 'rails.png'
    assert_match /rails.png/, u.image.url
    assert_match /rails.png/, u.source.avatar
    assert_match /rails.png/, u.source.image

    stub_config 'checkdesk_base_url', 'http://check.url' do
      info = {"image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"}
      create_omniauth_user provider: 'slack', current_user: u, info: info
      assert_match /rails.png/, u.source.file.url
      assert_equal info['image'], Source.find(u.source_id).avatar
      assert_match /rails.png/, u.source.image
    end
  end

  test "should not delete user if medias or sources associated to his profile" do
    u = create_user
    u2 = create_user
    pm = create_project_media user: u
    ps = create_project_source user: u
    assert_not u.destroy
    pm.user = u2; pm.save!
    assert_not u.destroy
    ps.user = u2; ps.save!
    assert u.destroy
  end

  test "should get profile image if user has no source" do
    u = create_user
    assert_not_nil u.source
    u.update_columns(source_id: nil)
    assert_nothing_raised do
      u.reload.profile_image
    end
  end

  test "should not have bot events" do
    u = create_user
    assert_equal '', u.bot_events
  end

  test "should not be a bot" do
    u = create_user
    assert !u.is_bot
  end

  test "should not accept terms by default" do
    u = create_user
    assert_nil u.last_accepted_terms_at
  end

  test "should return the last time that the terms were updated" do
    assert User.terms_last_updated_at > 0
  end

  test "should return the last time that the terms of service were updated" do
    assert User.terms_last_updated_at_by_page(:tos) > 0
  end

  test "should return the last time that the Smooch terms of service were updated" do
    assert User.terms_last_updated_at_by_page(:tos_smooch) > 0
  end

  test "should return the last time that the terms of privacy were updated" do
    assert User.terms_last_updated_at_by_page(:privacy_policy) > 0
  end

  test "should return the last time that invalid terms were updated" do
    assert_equal 0, User.terms_last_updated_at_by_page(:invalid)
  end

  test "should not crash but notify if could not get the last time that the terms were updated" do
    stub_config('tos_url', 'invalid-tos-url') do
      assert_nothing_raised do
        assert_equal 0, User.terms_last_updated_at
      end
    end
  end

  test "should return if user accepted terms" do
    u = create_user
    assert !u.reload.accepted_terms
    u.last_accepted_terms_at = Time.parse('2018-08-01')
    u.save!
    assert !u.reload.accepted_terms
    u.last_accepted_terms_at = Time.now
    u.save!
    assert u.reload.accepted_terms
  end

  test "should accept terms" do
    u = create_user
    assert !u.reload.accepted_terms
    u.accept_terms = false
    assert !u.reload.accepted_terms
    u.accept_terms = true
    assert u.reload.accepted_terms
  end

  test "should invite and accept users with three cases" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    t2 = create_team
    create_team_user team: t2, user: u, role: 'owner'
    # case A (non existing user to one team)
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: 'test1@local.com'}]
      User.send_user_invitation(members)
      iu = User.where(email: 'test1@local.com').last
      assert iu.is_invited?
      assert_equal [iu.read_attribute(:raw_invitation_token)], iu.team_users.map(&:raw_invitation_token)
    end
    # case B (non existing user to multiple teams)
    u1 = User.where(email: 'test1@local.com').last
    with_current_user_and_team(u, t2) do
      members = [{role: 'contributor', email: 'test1@local.com'}]
      User.send_user_invitation(members)
      u1.reload
      assert u1.reload.is_invited?
      token = u1.read_attribute(:raw_invitation_token)
      assert_equal [token, token], u1.team_users.map(&:raw_invitation_token)
    end
    # case C (existing user to one or multiple team)
    u3 = create_user email: 'test3@local.com'
    with_current_user_and_team(u, t) do
      assert_not u3.is_invited?
      members = [{role: 'contributor', email: 'test3@local.com'}]
      User.send_user_invitation(members)
      u3.reload
      assert_nil u3.read_attribute(:raw_invitation_token)
      assert_not_nil u3.team_users.map(&:raw_invitation_token)
      assert u3.is_invited?
    end
    with_current_user_and_team(u, t2) do
      assert_not u3.is_invited?
       members = [{role: 'contributor', email: 'test3@local.com'}]
       User.send_user_invitation(members)
       u3.reload
       assert_nil u3.read_attribute(:raw_invitation_token)
       assert_equal 2, u3.team_users.map(&:raw_invitation_token).uniq.size
       assert u3.is_invited?
    end
    # Accept invitation for case A & Case B
    u1_token = u1.reload.read_attribute(:raw_invitation_token)
    Team.current = nil
    User.current = nil
    User.accept_team_invitation(u1_token, t.slug)
    assert_not u1.reload.is_invited?(t)
    assert u1.is_invited?(t2)
    User.accept_team_invitation(u1_token, t2.slug)
    assert_not u1.is_invited?(t2)
    # Accept invitation for case C
    u3_token = u3.team_users.where(team_id: t.id).last.raw_invitation_token
    User.accept_team_invitation(u3_token, t.slug)
    assert_not u3.is_invited?(t)
    assert u3.is_invited?(t2)
    u3_token = u3.team_users.where(team_id: t2.id).last.raw_invitation_token
    User.accept_team_invitation(u3_token, t2.slug)
    assert_not u3.is_invited?(t2)
  end

  test "should invite users" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: 'test1@local.com'}, {role: 'journalist', email: 'test2@local.com'}]
      assert_difference ['User.count', 'TeamUser.count'], 2 do
        User.send_user_invitation(members)
      end
    end
    u1 = User.where(email: 'test1@local.com').last
    assert_equal u1.name, 'test1'
    tu1 = TeamUser.where(team_id: t.id, user_id: u1.id).last
    assert_equal tu1.role, 'contributor'
    assert_equal tu1.status, 'invited'
    assert_equal tu1.invited_by_id, u.id
    u2 = User.where(email: 'test2@local.com').last
    assert_equal u2.name, 'test2'
    tu2 = TeamUser.where(team_id: t.id, user_id: u2.id).last
    assert_equal tu2.role, 'journalist'
    assert_equal tu2.status, 'invited'
    assert_equal tu2.invited_by_id, u.id
    # test invited multiple emails
    with_current_user_and_team(u, t) do
      members = [{role: 'journalist', email: 'test3@local.com,test4@local.com'}]
      assert_difference ['User.count', 'TeamUser.count'], 2 do
        User.send_user_invitation(members)
      end
    end
    # invite existing user
    members = [{role: 'journalist', email: u1.email}]
    # A) for same team
    with_current_user_and_team(u, t) do
      assert_no_difference ['User.count', 'TeamUser.count'] do
        User.send_user_invitation(members)
      end
      tu1.status = 'member'; tu1.save!
      assert_no_difference ['User.count', 'TeamUser.count'] do
        User.send_user_invitation(members)
      end
    end
    # B)for new team
    User.current = Team.current = nil
    t2 = create_team
    create_team_user team: t2, user: u, role: 'owner'
    with_current_user_and_team(u, t2) do
      User.any_instance.stubs(:invite_existing_user).raises(RuntimeError)
      assert_no_difference ['User.count', 'TeamUser.count'] do
        User.send_user_invitation(members)
      end
      User.any_instance.unstub(:invite_existing_user)
      assert_no_difference 'User.count'do
        assert_difference 'TeamUser.count' do
          User.send_user_invitation(members)
        end
      end
    end
    assert_equal ['contributor', 'journalist'], u1.team_users.map(&:role).sort
  end

  test "should invite banned users" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    u1 = create_user email: 'test1@local.com'
    create_team_user team: t, user: u1, status: 'banned'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: u1.email}]
      User.send_user_invitation(members)
    end
    tu1 = TeamUser.where(team_id: t.id, user_id: u1.id).last
    assert_equal tu1.status, 'invited'
  end

  test "should cancel user invitation" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    u2 = create_user email: 'test2@local.com'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: 'test1@local.com, test2@local.com'}]
      User.send_user_invitation(members)
    end
    User.current = Team.current = nil
    t2 = create_team
    create_team_user team: t2, user: u, role: 'owner'
    with_current_user_and_team(u, t2) do
      members = [{role: 'contributor', email: 'test1@local.com, test2@local.com'}]
      User.send_user_invitation(members)
    end
    User.current = Team.current = nil
    user = User.where(email: 'test1@local.com').last
    with_current_user_and_team(u, t) do
      assert_difference 'TeamUser.count', -1 do
        User.cancel_user_invitation(user)
      end
      assert_difference 'TeamUser.count', -1 do
        User.cancel_user_invitation(u2)
      end
    end
    User.current = Team.current = nil
    with_current_user_and_team(u, t2) do
      assert_difference ['TeamUser.count', 'User.count'], -1 do
        User.cancel_user_invitation(user)
      end
      assert_difference 'TeamUser.count', -1 do
        assert_no_difference 'User.count' do
          User.cancel_user_invitation(u2)
        end
      end
    end
  end

  test "should not accept invalid invitation" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    u2 = create_user email: 'test1@local.com'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: 'test1@local.com'}]
      User.send_user_invitation(members)
    end
    user = User.where(email: 'test1@local.com').last
    tu = user.team_users.last
    token = tu.raw_invitation_token
    invitation_date = tu.created_at
    # Accept with invalid slug
    result = User.accept_team_invitation(token, 'invalidslug')
    assert_not_empty result.errors
    # Accept with invalid tokem
    result = User.accept_team_invitation('invalidtoken', t.slug)
    assert_not_empty result.errors
    # Accept with expired token
    old_date = invitation_date - User.invite_for - 1.day
    tu.update_column(:created_at, old_date)
    result = User.accept_team_invitation(token, t.slug)
    assert_not_empty result.errors
  end

  test "should not send welcome email for invited user" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    stub_config 'send_welcome_email_on_registration', true do
      with_current_user_and_team(u, t) do
        assert_difference 'ActionMailer::Base.deliveries.size', 1 do
          members = [{role: 'contributor', email: 'test1@local.com'}]
          User.send_user_invitation(members)
        end
      end
    end
  end

  test "should send invitaion using invitation emaill not primary email" do
    t = create_team
    u = create_user email: 'primary@local.com'
    create_team_user team: t, user: u, role: 'owner'
    a = create_account source: u.source, user: u, provider: 'facebook', email: 'account@local.com'
    # create a new team and invite existing user with email of associated account
    t2 = create_team
    u2 = create_user
    create_team_user team: t2, user: u2, role: 'owner'
    # invite existing user
    members = [{role: 'journalist', email: 'account@local.com'}]
    # A) for same team
    with_current_user_and_team(u2, t2) do
      assert_difference 'TeamUser.count', 1 do
        User.send_user_invitation(members)
      end
    end
    assert_equal ['account@local.com'], t2.invited_mails(t2)
  end

  test "should allow user to delete own account" do
    t = create_team
    user = create_user
    tu = create_team_user team: t, user: user, role: 'contributor'
    s = user.source
    create_account source: s
    pm = create_project_media user: user
    ps = create_project_source user: user
    with_current_user_and_team(user, t) do
      User.delete_check_user(user)
    end
    user = user.reload
    assert_equal "Anonymous", user.name, user.login
    assert_nil user.source, user.email
    assert_not user.is_active?
    assert_equal pm.reload.user_id, user.id
    assert_equal ps.reload.user_id, user.id
    assert_equal 'banned', tu.reload.status
    user = create_user
    with_current_user_and_team(user, t) do
      Source.any_instance.stubs(:destroy).raises(RuntimeError)
      assert_raise RuntimeError do
        User.delete_check_user(user)
      end
      Source.any_instance.unstub(:destroy)
    end
  end

  test "should allow user for multi login account" do
    u = create_user
    assert_no_difference 'User.count' do
      assert_difference 'Account.count', 1 do
        create_omniauth_user provider: 'twitter', uid: '123456', current_user: u
      end
    end
  end

  test "should get user through omniauth info" do
    u = create_omniauth_user uid: '123456', provider: 'twitter'
    assert_equal u, User.find_with_omniauth('123456', 'twitter')
  end

  test "should get user through token" do
    u = create_user token: 'test'
    assert_equal u, User.find_with_token('test')
  end

  test "should get social accounts for login" do
    u = create_omniauth_user provider: 'twitter'
    a = create_account source: u.source, user: u, provider: 'facebook'
    a2 = create_account source: u.source, user: u, uid: ''
    assert_equal 2, u.get_social_accounts_for_login.count
    fb_account = u.get_social_accounts_for_login({provider: 'facebook'})
    assert_equal 1, fb_account.count
    assert_equal a, fb_account.first
  end

  test "should get user accounts and providers" do
    u = create_omniauth_user provider: 'twitter'
    s = u.source
    omniauth_info = {"info"=> { "name" => "test" } }
    create_account source: s, user: u, provider: 'slack', uid: '123456', omniauth_info: omniauth_info
    create_account source: s, user: u, provider: 'slack', uid: '987654', omniauth_info: omniauth_info
    assert_equal 3, u.get_social_accounts_for_login.count
    assert_equal 0, u.get_social_accounts_for_login({provider: 'facebook'}).count
    assert_equal 1, u.get_social_accounts_for_login({provider: 'twitter'}).count
    assert_equal 2, u.get_social_accounts_for_login({provider: 'slack'}).count
    assert_equal 1, u.get_social_accounts_for_login({provider: 'slack', uid: '123456'}).count
    providers = u.providers
    assert_equal 4, providers.count
    assert_equal ['facebook', 'twitter', 'slack', 'google_oauth2'].sort, providers.collect{|p| p[:key]}.sort
    # connect using FB
    create_account source: s, user: u, provider: 'facebook', uid: '987654', omniauth_info: omniauth_info
    assert_equal 1, u.get_social_accounts_for_login({provider: 'facebook'}).count
    providers = u.providers
    assert_equal 4, providers.count
    assert_equal ['facebook', 'twitter', 'slack', 'google_oauth2'].sort, providers.collect{|p| p[:key]}.sort
  end

  test "should disconnect social account" do
    u = create_omniauth_user provider: 'twitter', uid: '123456'
    u.disconnect_login_account('twitter', '123456')
    assert_equal 0, u.get_social_accounts_for_login.count
    u2 = create_omniauth_user provider: 'slack', uid: '456789'
    a = u2.get_social_accounts_for_login({provider: 'slack', uid: '456789'}).first
    create_account_source account: a
    assert_equal 2, a.sources.count
    assert_not_nil a.uid, a.provider
    assert_not_nil a.token, a.omniauth_info
    u2.disconnect_login_account('slack', '456789')
    assert_equal 0, u2.get_social_accounts_for_login.count
    a = Account.find(a.id)
    assert_not_nil a
    assert_equal 1, a.sources.count
    assert_nil a.uid, a.provider
    assert_nil a.token, a.omniauth_info
    assert_nil a.email
  end

  test "should merge confirmed accounts" do
    u = create_user confirm: false
    assert_no_difference 'User.count' do
      assert_difference 'Account.count' do
        create_omniauth_user email: u.email
      end
    end
    u = create_omniauth_user provider: 'twitter', email: '', uid: '123456'
    u2 = create_omniauth_user provider: 'facebook', email: 'test@local.com'
    tu = create_team_user user: u2
    pm = create_project_media user: u2
    ps = create_project_source user: u2
    s2_id = u2.source.id
    u2_id = u2.id
    u3 = create_omniauth_user provider: 'twitter', uid: '123456', email: 'test@local.com'
    assert_equal u.id, u3.id
    accounts = u.source.accounts
    assert_equal 2, accounts.count
    assert_equal ['facebook', 'twitter'].sort, accounts.map(&:provider).sort
    assert_equal u.id, pm.reload.user_id
    assert_equal u.id, ps.reload.user_id
    assert_equal u.id, tu.reload.user_id
    assert_raises ActiveRecord::RecordNotFound do
      User.find(u2_id)
    end
    assert_raises ActiveRecord::RecordNotFound do
      Source.find(s2_id)
    end
  end

  test "should keep higher role when merge accounts in same team" do
    t = create_team
    u = create_omniauth_user provider: 'twitter', email: 'test@local.com'
    u2 = create_omniauth_user provider: 'facebook', email: 'test2@local.com'
    create_team_user team: t, user: u, role: 'contributor'
    create_team_user team: t, user: u2, role: 'journalist'
    assert_equal 2, t.team_users.count
    create_omniauth_user provider: 'slack', email: 'test@local.com', current_user: u2
    assert_equal 1, t.team_users.count
    assert_equal ['journalist'], t.team_users.map(&:role)
  end

  test "should merge two existing accounts" do
    u = create_omniauth_user provider: 'twitter', email: '', uid: '123456'
    u2 = create_omniauth_user provider: 'twitter', email: '', uid: '345678'
    assert_no_difference 'User.count' do
      create_omniauth_user provider: 'twitter', email: 'test_a@local.com', uid: '123456'
    end
    create_omniauth_user provider: 'twitter', email: 'test_b@local.com', uid: '345678', current_user: u
    assert_equal 2, u.source.accounts.count
    assert_raises ActiveRecord::RecordNotFound do
      User.find(u2.id)
    end
    # test connect with same provider
    create_omniauth_user provider: 'twitter', email: 'test_a@local.com', uid: '123456', current_user: u
  end

  test "should merge two users with same source" do
    u = create_user
    s = u.source
    u2 = create_user
    u2.update_columns(source_id: s.id)
    assert_nothing_raised do
      u.merge_with(u2)
    end
    assert Source.exists?(s.id)
  end

  test "should keep email based login when merge users" do
    u = create_user email: 'test@local.com', token: '123456', is_admin: true
    u2 = create_omniauth_user
    assert_not u2.is_admin?
    assert_not u2.encrypted_password?
    u2.merge_with(u)
    assert_equal 'test@local.com', u2.reload.email
    assert_equal '123456', u2.reload.token
    assert u2.encrypted_password?
    assert u2.is_admin?
  end

  test "should login or register with invited email" do
    t = create_team
    u = create_user
    email = 'test@local.com'
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: email}]
      User.send_user_invitation(members)
    end
    Team.current = User.current = nil
    u1 = User.where(email: email).last
    assert u1.invited_to_sign_up?
    assert_equal ["invited"], u1.team_users.map(&:status)
    assert_no_difference 'User.count' do
      create_omniauth_user email: email
    end
    assert_equal ["member"], u1.reload.team_users.map(&:status)
    # try to register with same email
    assert_raises ActiveRecord::RecordInvalid do
      create_user email: email
    end
  end

  test "should request to join invited team" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    u2 = create_user
    # request to join team with invitation period
    with_current_user_and_team(u, t) do
      members = [{role: 'owner', email: u2.email}]
      User.send_user_invitation(members)
    end
    with_current_user_and_team(u2, t) do
      create_team_user team: t, user: u2, status: 'requested'
    end
    tu = u2.team_users.where(team_id: t.id).last
    assert_equal 'owner', tu.role
    assert_equal 'member', tu.status
    # request to join team with expired invitaion
    t2 = create_team
    create_team_user team: t2, user: u, role: 'owner'
    with_current_user_and_team(u, t2) do
      members = [{role: 'owner', email: u2.email}]
      User.send_user_invitation(members)
    end
    tu = u2.team_users.where(team_id: t2.id).last
    # expire invitation
    old_date = tu.created_at - User.invite_for - 1.day
    tu.update_column(:created_at, old_date)
    with_current_user_and_team(u2, t2) do
      create_team_user team: t2, user: u2, status: 'requested'
    end
    tu = u2.team_users.where(team_id: t2.id).last
    assert_equal 'owner', tu.role
    assert_equal 'requested', tu.status
  end

  test "should generate password token" do
    token = User.generate_password_token(nil)
    assert_nil token
    u = create_user
    token = User.generate_password_token(u.id)
    assert_not_nil token
  end

  test "should have 2FA for email based user" do
    u = create_user password: 'test1234'
    assert_nil u.otp_secret
    data = u.two_factor
    assert_not_nil u.otp_secret
    assert data[:can_enable_otp]
    assert_not data[:otp_required]
    assert_not_empty data[:qrcode_svg]
    options = { otp_required: true, password: 'invalidPassword' }
    assert_raise RuntimeError do
      u.two_factor=(options)
    end
    options[:password] = 'test1234'
    options[:qrcode] = 'test1234'
    assert_raise RuntimeError do
      u.two_factor=(options)
    end
    options[:qrcode] = u.current_otp
    assert_nothing_raised do
      u.two_factor=(options)
    end
    data = u.reload.two_factor
    assert data[:otp_required]
    assert_empty data[:qrcode_svg]
    # test otp_backup codes
    codes = u.generate_otp_codes
    assert_equal 5, codes.size
    # test with nil email
    u.update_columns(email: nil)
    assert_raise RuntimeError do
      u.reload.two_factor=(options)
    end
    # should not allow user to enable 2FA for social accounts
    u2 = create_omniauth_user
    data = u2.two_factor
    assert_not data[:can_enable_otp]
    options = { otp_required: true }
    assert_raise RuntimeError do
      u2.two_factor=(options)
    end
  end

  test "should reset or change user password" do
    u = create_user password: 'test1234'
    rand_id = u.id + rand(100)
    options = { id: rand_id, current_password: 'invalidpassword', password: 'test5678', password_confirmation: 'test5678' }
    User.stubs(:current).returns(u)
    # test change password
    assert_raises ActiveRecord::RecordNotFound do
      User.reset_change_password(options)
    end
    options[:id] = u.id
    assert u.reload.valid_password?('test1234')
    assert_raises RuntimeError do
      User.reset_change_password(options)
    end
    assert u.reload.valid_password?('test1234')
    options[:current_password] = 'test1234'
    User.reset_change_password(options)
    assert u.reload.valid_password?('test5678')
    # test reset password
    token = User.generate_password_token(u.id)
    options[:reset_password_token] = token
    options[:password] = options[:password_confirmation] = 'test1289'
    User.reset_change_password(options)
    assert u.reload.valid_password?('test1289')
    User.unstub(:current)
  end

end
