require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediaTest < ActiveSupport::TestCase
  def setup
    super
    Media.destroy_all
    Annotation.delete_index
    Annotation.create_index
    sleep 1
  end

  test "should create media" do
    assert_difference 'Media.count' do
      create_valid_media
    end
  end

  test "should not save media without url" do
    media = Media.new
    assert_not media.save
  end

  test "should set pender data for media" do
    media = create_valid_media
    assert_not_empty media.data
  end

  test "should have annotations" do
    m = create_valid_media
    c1 = create_comment
    c2 = create_comment
    c3 = create_comment
    m.add_annotation(c1)
    m.add_annotation(c2)
    sleep 1
    assert_equal [c1.id, c2.id].sort, m.reload.annotations.map(&:id).sort
  end

  test "should get user id" do
    m = create_valid_media
    assert_nil m.send(:user_id_callback, 'test')
    u = create_user(name: 'test')
    assert_equal u.id, m.send(:user_id_callback, 'test')
  end

  test "should get account id" do
    m = create_valid_media
    assert_nil m.send(:account_id_callback, 'http://meedan.com')
    assert_equal m.account.id, m.send(:account_id_callback, m.account.url)
  end

  test "should create version when media is created" do
    m = create_valid_media
    assert_equal 1, m.versions.size
  end

  test "should create version when media is updated" do
    m = create_valid_media
    assert_equal 1, m.versions.size
    m = m.reload
    m.project = create_project
    m.save!
    assert_equal 2, m.reload.versions.size
  end

  test "should not update url when media is updated" do
    m = create_valid_media
    m = m.reload
    url = m.url
    m.url = 'http://meedan.com'
    m.save
    assert_not_equal m.url, url
  end

  test "should not duplicate media url" do
    m = create_valid_media
    m2 = Media.new
    m2.url = m.url
    assert_not m2.save
  end


end
