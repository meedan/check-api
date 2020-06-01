require_relative '../test_helper'

class AccountSourceTest < ActiveSupport::TestCase
   def setup
    super
    @a = create_valid_account
    @s = create_source
  end

  test "should create account source" do
    assert_difference 'AccountSource.count' do
      create_account_source account: @a, source: @s
    end
  end

  test "should have a source and account" do
    assert_no_difference 'AccountSource.count' do
      assert_raise ActiveRecord::RecordInvalid do
        create_account_source account: nil, source: @s
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_account_source source: nil, account: @a
      end
    end
  end

  test "should create account if url set" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    assert_difference 'AccountSource.count' do
      as = create_account_source url: url, source: @s
      assert_equal as.account.url, url
    end
    # create account source for existing url
    s2 = create_source
    assert_difference 'AccountSource.count' do
      as = create_account_source url: @a.url, source: s2
    end
  end

  test "should create a unique account per source" do
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    Team.stubs(:current).returns(t)
    s = create_source
    assert_difference 'AccountSource.count' do
      a = create_account url: url, source: s
    end
    Team.unstub(:current)
    # test duplicate accounts for user profile
    url = 'http://test2.com'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    s = u.source
    assert_difference 'AccountSource.count' do
      create_account_source source: s, url: url
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_account_source source: s, url: url
    end
  end

end
