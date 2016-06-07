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

end
