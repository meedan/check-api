require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ApiKeyTest < ActiveSupport::TestCase
  test "should create API key" do
    assert_difference 'ApiKey.count' do
      create_api_key
    end
  end

  test "should generate expiration date" do
    t = Time.parse('2015-01-01 09:00:00')
    Time.stubs(:now).returns(t)
    k = create_api_key
    Time.unstub(:now)
    assert_equal Time.parse('2015-01-31 09:00:00'), k.reload.expire_at
  end

  test "should generate access token" do
    k = create_api_key
    assert_kind_of String, k.reload.access_token
  end

  test "should generate random data" do
    assert_kind_of String, random_string
    assert_kind_of Integer, random_number
    assert_kind_of String, random_email
  end

  test "should have application" do
    ApiKey.stubs(:applications).returns([nil, 'test'])
    k1 = create_api_key
    assert_nil k1.application
    k2 = create_api_key application: 'test'
    assert_equal 'test', k2.application
    assert_raises ActiveRecord::RecordInvalid do
      create_api_key application: 'invalid'
    end
  end
end
