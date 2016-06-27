require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AccountTest < ActiveSupport::TestCase
  def setup
    super
    @url = 'https://www.youtube.com/user/MeedanTube'
  end

  test "should create account" do
    assert_difference 'Account.count' do
      PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
        create_account(url: @url)
      end
    end
  end

  test "should not save account without url" do
    account = Account.new
    assert_not account.save
  end

  test "set pender data for account" do
    account = nil
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      account = create_account(url: @url)
    end
    assert_not_empty account.data
  end

end
