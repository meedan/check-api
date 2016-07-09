require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class UserTest < ActiveSupport::TestCase

  test "should create user" do
    assert_difference 'User.count' do
      create_user
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
    assert_equal u.source, Source.last
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
      PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
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
end
