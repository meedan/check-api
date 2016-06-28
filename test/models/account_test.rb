require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AccountTest < ActiveSupport::TestCase
  def setup
    super
    @url = 'https://www.youtube.com/user/MeedanTube'
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      @account = create_account(url: @url)
    end
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
    u = create_user name: 'test'
    @account.user = u
    @account.save!
    assert_equal u.id, @account.send(:user_id_callback, 'test')
  end
end
