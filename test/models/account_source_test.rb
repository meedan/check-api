require_relative '../test_helper'

class AccountSourceTest < ActiveSupport::TestCase

  test "should create account source" do
    assert_difference 'AccountSource.count' do
      create_account_source
    end
  end

  test "should have a source and account" do
    assert_no_difference 'AccountSource.count' do
      assert_raise ActiveRecord::RecordInvalid do
        create_account_source account: nil
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_account_source source: nil
      end
    end
  end

  test "should create account if url set" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    assert_difference 'Account.count' do
      as = create_account_source url: url
      assert_equal as.account.url, url
    end
  end

end
