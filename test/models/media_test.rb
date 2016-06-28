require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediaTest < ActiveSupport::TestCase
  def setup
    super
    Media.destroy_all
    Annotation.delete_index
    Annotation.create_index
    sleep 1
    @url = 'https://www.youtube.com/user/MeedanTube'
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      @account = create_account(url: @url)
      @m = create_media(url: @url, account: @account)
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

  test "should set pender data for media" do
    media = nil
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      media = create_media(url: @url, account: @account)
    end
    assert_not_empty media.data
  end

  test "should have annotations" do
    c1 = create_comment
    c2 = create_comment
    c3 = create_comment
    @m.add_annotation(c1)
    @m.add_annotation(c2)
    sleep 1
    assert_equal [c1.id, c2.id].sort, @m.reload.annotations.map(&:id).sort
  end

  test "should get user id" do
    assert_nil @m.send(:user_id_callback, 'test')
    u = create_user(name: 'test')
    assert_equal u.id, @m.send(:user_id_callback, 'test')
  end

  test "should get account id" do
    assert_nil @m.send(:account_id_callback, 'http://meedan.com')
    assert_equal @account.id, @m.send(:account_id_callback, @url)
  end

  test "should create version when media is created" do
    m = nil
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) { m = create_media(url: @url, account: @account) }
    assert_equal 1, m.versions.size
  end

  test "should create version when media is updated" do
    m = nil
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) { m = create_media(url: @url, account: @account) }
    assert_equal 1, m.versions.size
    m = m.reload
    m.project = create_project
    m.save!
    assert_equal 2, m.reload.versions.size
  end
end
