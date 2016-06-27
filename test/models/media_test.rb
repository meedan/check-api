require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediaTest < ActiveSupport::TestCase
  def setup
    super
    @url = 'https://www.youtube.com/user/MeedanTube'
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      @account = create_account(url: @url)
    end
  end

  test "should create media" do
    assert_difference 'Media.count' do
      PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
        create_media(url: @url, account: @account)
      end
    end
  end

  test "should not save media without url" do
    media = Media.new
    assert_not media.save
  end

  test "set pender data for media" do
    media = nil
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      media = create_media(url: @url, account: @account)
    end
    assert_not_empty media.data
  end
end
