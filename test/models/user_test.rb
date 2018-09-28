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
      create_user password: '', provider: 'twitter'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_user password: '', provider: ''
    end
  end

  test "should not require email" do
    u = nil
    assert_nothing_raised do
      u = create_user email: ''
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
      create_user url: nil, provider: 'facebook'
    end
  end

  test "should not create account if user has no provider" do
    assert_no_difference 'Account.count' do
      create_user provider: '', url: 'http://meedan.com'
    end
  end

  test "should create account if user has provider and url" do
    assert_difference 'Account.count' do
      PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_url_private']) do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
        create_user provider: 'youtube', url: 'https://www.youtube.com/user/MeedanTube'
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
    u = create_user login: '', name: 'Foo Bar', email: ''
    assert_equal 'foo-bar', u.reload.login
  end

  test "should set login from email" do
    u = create_user login: '', name: 'Foo Bar', email: 'foobar@test.com'
    assert_equal 'foobar', u.reload.login
  end

  test "should set uuid" do
    assert_difference 'User.count', 2 do
      create_user login: '', name: 'Foo Bar', email: 'foobar1@test.com', provider: '', uuid: ''
      create_user login: '', name: 'Foo Bar', email: 'foobar2@test.com', provider: '', uuid: ''
    end
  end

  test "should send welcome email when user is created" do
    stub_config 'send_welcome_email_on_registration', true do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        create_user provider: '', skip_confirmation: true
      end
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        create_user provider: 'twitter'
        create_user provider: 'facebook'
      end
    end

    stub_config 'send_welcome_email_on_registration', false do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        create_user provider: '', skip_confirmation: true
        create_user provider: 'twitter'
        create_user provider: 'facebook'
      end
    end
  end

  test "should send email when user email is duplicate" do
    u = create_user provider: 'facebook'
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_raises ActiveRecord::RecordInvalid do
        create_user email: u.email
      end
    end
  end

  test "should not add duplicate mail" do
    u = create_user
    assert_no_difference 'User.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_user email: u.email
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
      assert_raises ActiveRecord::RecordInvalid do
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
      create_user url: 'http://twitter.com/meedan', provider: 'twitter'
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
    u = create_user provider: '', email: 'user@email.com'
    assert_equal 'user@email.com', u.handle
    u = create_user provider: 'facebook', login: 'user', omniauth_info: { 'url' => 'https://facebook.com/10157109339765023' }
    assert_equal 'https://facebook.com/10157109339765023', u.handle
  end

  test "should get handle for Slack" do
    u = create_user provider: 'slack', omniauth_info: { 'extra' => { 'raw_info' => { 'url' => 'https://meedan.slack.com' } } }, login: 'caiosba'
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
    u = create_user provider: 'twitter'
    assert !u.send(:confirmation_required?)
    u = create_user provider: ''
    assert u.send(:confirmation_required?)
  end

  test "should require confirmation after update email" do
    u = create_user provider: 'twitter'
    assert u.is_confirmed?
    u = create_user email: 'foo@bar.com', provider: ''
    assert_not u.is_confirmed?
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
    u = create_user provider: 'facebook', uuid: '123456', email: 'user@fb.com'
    assert_equal '123456', u.reload.uuid
    User.current = create_user
    User.update_facebook_uuid(OpenStruct.new({ provider: 'facebook', uid: '654321', info: OpenStruct.new({ email: 'user@fb.com' })}))
    User.current = nil
    assert_equal '654321', u.reload.uuid
  end

  test "should not update Facebook id if email not set" do
    u1 = create_user provider: 'facebook', uuid: '123456', email: ''
    u2 = create_user provider: 'facebook', uuid: '456789', email: ''
    assert_equal '123456', u1.reload.uuid
    assert_equal '456789', u2.reload.uuid
    User.current = create_user
    User.update_facebook_uuid(OpenStruct.new({ provider: 'facebook', uid: '456789', info: OpenStruct.new({ email: '' })}))
    User.current = nil
    assert_equal '123456', u1.reload.uuid
    assert_equal '456789', u2.reload.uuid
  end

  test "should save valid languages" do
    u = create_user
    value = [{"id": "en","title": "English"}]
    assert_nothing_raised do
      u.set_languages(value)
      u.save!
    end
  end

  test "should not save languages if is not valid" do
    u = create_user
    variations = [
      'invalid_language',
      ['invalid_language'],
      [{ id: 'en' }],
      [{ title: 'English' }]
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

    u = create_user provider: 'facebook', uuid: '1062518227129764', email: 'user@fb.com', url: url1
    assert_equal '1062518227129764', u.reload.uuid
    account = u.accounts.first
    assert_equal url1, account.url

    url2 = 'https://www.facebook.com/100001147915899'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: '{"type":"media","data":{"url":"' + url2 + '/","type":"profile"}}')
    User.update_facebook_uuid(OpenStruct.new({ provider: 'facebook', uid: '100001147915899', info: OpenStruct.new({ email: 'user@fb.com' }), url: url2}))
    assert_equal '100001147915899', u.reload.uuid
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

  test "should set send_email_notifications" do
    u = create_user
    u.send_email_notifications = true
    u.save!
    assert u.get_send_email_notifications
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
    omniauth_info = {"provider"=>"slack", "info"=> {"nickname"=>"daniela", "team"=>"meedan", "user"=>"daniela", "name"=>"daniela feitosa", "description"=>"", "image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"}, "url"=>"https://meedan.slack.com/team/daniela"}
    u = create_user provider: 'slack', omniauth_info: omniauth_info, url: omniauth_info['url']
    account = u.account
    assert account.created_on_registration?
    assert_equal omniauth_info['url'], account.url
    assert_equal omniauth_info['info']['nickname'], account.data['username']
    assert_equal omniauth_info['info']['name'], account.data['author_name']
    assert_equal omniauth_info['info']['description'], account.data['description']
    assert_equal omniauth_info['info']['image'], account.data['picture']
    assert_equal omniauth_info['url'], account.data['url']
  end

  test "should create source with image on omniauth data" do
    omniauth_info = {"info"=> { "image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"} }

    u = create_user provider: 'slack', omniauth_info: omniauth_info
    source = u.source
    assert_equal omniauth_info['info']['image'], source.avatar
  end

  test "should create source with default image" do
    u = create_user
    source = u.source
    assert_match /images\/user.png/, source.avatar
  end

  test "should set source image when call user from omniauth" do
    u = create_user provider: 'twitter', uuid: '12345'
    assert_match /images\/user.png/, u.source.avatar

    credentials = OpenStruct.new({ token: '1234', secret: 'secret'})
    info = OpenStruct.new({ email: 'user@fb.com', name: 'John', image: 'picture.png' })
    auth = OpenStruct.new({ provider: 'twitter', uid: '12345', credentials: credentials, info: info})
    omniauth_info = {"info"=> { "image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"} }
    User.any_instance.stubs(:omniauth_info).returns(omniauth_info)
    User.from_omniauth(auth)
    assert_equal omniauth_info['info']['image'], User.find(u.id).source.avatar
    assert_equal omniauth_info['info']['image'], User.find(u.id).source.image
    User.any_instance.unstub(:omniauth_info)
  end

  test "should set user image as source image and return the uploaded image instead of omniauth" do
    u = create_user image: 'rails.png', provider: 'twitter', uuid: '12345'
    assert_match /rails.png/, u.image.url
    assert_match /rails.png/, u.source.avatar
    assert_match /rails.png/, u.source.image

    credentials = OpenStruct.new({ token: '1234', secret: 'secret'})
    info = OpenStruct.new({ email: 'user@fb.com', name: 'John', image: 'picture.png' })
    auth = OpenStruct.new({ provider: 'twitter', uid: '12345', credentials: credentials, info: info})
    omniauth_info = {"info"=> { "image"=>"https://avatars.slack-edge.com/2016-08-30/74454572532_7b40a563ce751e1c1d50_192.jpg"} }
    stub_config 'checkdesk_base_url', 'http://check.url' do
      User.any_instance.stubs(:omniauth_info).returns(omniauth_info)
      User.from_omniauth(auth)

      assert_match /rails.png/, u.source.file.url
      assert_equal omniauth_info['info']['image'], Source.find(u.source_id).avatar
      assert_match /rails.png/, u.source.image

      User.any_instance.unstub(:omniauth_info)
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
    u = User.create! name: 'Dwight Knell', login: 'dwight', provider: '', password: '12345678', password_confirmation: '12345678', email: 'dwight@hackshackers.com', is_active: true
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
end
