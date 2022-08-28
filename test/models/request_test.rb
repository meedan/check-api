require_relative '../test_helper'

class RequestTest < ActiveSupport::TestCase
  def setup
    super
    Sidekiq::Testing.inline!
    Request.delete_all
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
  end

  test "should create request" do
    assert_difference 'Request.count' do
      create_request
    end
  end

  test "should belong to media" do
    m = create_valid_media
    r = create_request media: m
    assert_equal m, r.media
  end

  test "should belong to similar request" do
    r1 = create_request
    r2 = create_request
    r1.similar_to_request = r2
    r1.save!
    assert_equal r2, r1.reload.similar_to_request
    assert_equal [r1], r2.reload.similar_requests
  end

  test "should get media for image" do
    image_url_1 = random_url
    image_url_2 = random_url
    m1 = nil
    m2 = nil
    WebMock.stub_request(:get, image_url_1).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    WebMock.stub_request(:get, image_url_2).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    assert_difference 'UploadedImage.count' do
      m1 = Request.get_media_from_query('image', "Foo #{image_url_1} bar #{random_url} test")
    end
    assert_kind_of UploadedImage, m1
    assert_no_difference 'UploadedImage.count' do
      m2 = Request.get_media_from_query('image', "Test #{image_url_2} foo #{random_url} bar")
    end
    assert_kind_of UploadedImage, m2
    assert_equal m1, m2
  end

  test "should get media for audio" do
    audio_url_1 = random_url
    audio_url_2 = random_url
    m1 = nil
    m2 = nil
    WebMock.stub_request(:get, audio_url_1).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
    WebMock.stub_request(:get, audio_url_2).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
    assert_difference 'UploadedAudio.count' do
      m1 = Request.get_media_from_query('audio', "Foo #{audio_url_1} bar #{random_url} test")
    end
    assert_kind_of UploadedAudio, m1
    assert_no_difference 'UploadedAudio.count' do
      m2 = Request.get_media_from_query('audio', "Test #{audio_url_2} foo #{random_url} bar")
    end
    assert_kind_of UploadedAudio, m2
    assert_equal m1, m2
  end

  test "should get media for video" do
    video_url_1 = random_url
    video_url_2 = random_url
    m1 = nil
    m2 = nil
    WebMock.stub_request(:get, video_url_1).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp4')))
    WebMock.stub_request(:get, video_url_2).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp4')))
    assert_difference 'UploadedVideo.count' do
      m1 = Request.get_media_from_query('video', "Foo #{video_url_1} bar #{random_url} test")
    end
    assert_kind_of UploadedVideo, m1
    assert_no_difference 'UploadedVideo.count' do
      m2 = Request.get_media_from_query('video', "Test #{video_url_2} foo #{random_url} bar")
    end
    assert_kind_of UploadedVideo, m2
    assert_equal m1, m2
  end

  test "should get media for link" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","foo":"1"}}')
    m1 = nil
    m2 = nil
    assert_difference 'Link.count' do
      m1 = Request.get_media_from_query('text', "Foo #{url} bar")
    end
    assert_kind_of Link, m1
    assert_no_difference 'Link.count' do
      m2 = Request.get_media_from_query('text', "Bar #{url} foo")
    end
    assert_kind_of Link, m2
    assert_equal m1, m2
  end

  test "should get media for text" do
    text = random_string
    m1 = nil
    m2 = nil
    assert_difference 'Claim.count' do
      m1 = Request.get_media_from_query('text', text)
    end
    assert_kind_of Claim, m1
    assert_no_difference 'Claim.count' do
      m2 = Request.get_media_from_query('text', text)
    end
    assert_kind_of Claim, m2
    assert_equal m1, m2
  end

  test "should send text request to Alegre" do
    Bot::Alegre.stubs(:request_api).returns(true)
    assert_nothing_raised do
      create_request(media: create_claim_media)
    end
    Bot::Alegre.unstub(:request_api)
  end

  test "should send media request to Alegre" do
    Bot::Alegre.stubs(:request_api).returns(true)
    assert_nothing_raised do
      create_request(media: create_uploaded_image)
    end
    Bot::Alegre.unstub(:request_api)
  end

  test "should attach to similar text" do
    Bot::Alegre.stubs(:request_api).returns(true)
    f = create_feed
    m1 = Media.create! type: 'Claim', quote: 'Foo bar foo bar'
    r1 = create_request media: m1, feed: f
    m2 = Media.create! type: 'Claim', quote: 'Foo bar foo bar 2'
    r2 = create_request media: m2, feed: f
    response = { 'result' => [{ '_source' => { 'context' => { 'request_id' => r1.id } } }] }
    Bot::Alegre.stubs(:request_api).with('get', '/text/similarity/', { text: 'Foo bar foo bar 2', threshold: 0.85, context: { feed_id: f.id } }).returns(response)
    r2.attach_to_similar_request!
    assert_equal r1, r2.reload.similar_to_request
    assert_equal [r2], r1.reload.similar_requests
    Bot::Alegre.unstub(:request_api)
  end

  test "should attach to similar media" do
    Bot::Alegre.stubs(:request_api).returns(true)
    f = create_feed
    m1 = create_uploaded_image
    r1 = create_request request_type: 'image', media: m1, feed: f
    m2 = create_uploaded_image
    r2 = create_request request_type: 'image', media: m2, feed: f
    response = { 'result' => [{ 'context' => [{ 'request_id' => r1.id }] }] }
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', { url: m2.file.file.public_url, threshold: 0.85, context: { feed_id: f.id } }).returns(response)
    r2.attach_to_similar_request!
    assert_equal r1, r2.reload.similar_to_request
    assert_equal [r2], r1.reload.similar_requests
    Bot::Alegre.unstub(:request_api)
  end
end
