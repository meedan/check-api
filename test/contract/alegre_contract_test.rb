require_relative 'pact_helper'

class Bot::AlegreContractTest < ActiveSupport::TestCase
  include Pact::Consumer::Minitest

  def setup
    Sidekiq::Testing.fake!
    # Set up annotation types that we need that were previously provided by migrations
    create_metadata_stuff
    create_extracted_text_annotation_type
    create_flag_annotation_type
    create_annotation_type(annotation_type: 'language')

    t = create_team
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media team: t, media: m
    response = JSON.parse("{ \"text\": \"X X X\\n3\\nTranslate this sentence\\nو عندي وقت في الساعة العاشرة.\\n\" }")
    @extracted_text = response['text']
    @url = 'https://i.imgur.com/ewGClFQ.png'
    @url2 = 'https%3A%2F%2Fi.imgur.com%2FewGClFQ.png'
    @flags = {:flags=>{"adult"=>1, "spoof"=>1, "medical"=>2, "violence"=>1, "racy"=>1, "spam"=>0}}
  end

  def stub_similarity_requests(url, pm)
    WebMock.stub_request(:post, 'http://localhost:3100/text/similarity/').to_return(body: 'success')
    WebMock.stub_request(:delete, 'http://localhost:3100/text/similarity/').to_return(body: { success: true }.to_json)
    WebMock.stub_request(:post, 'http://localhost:3100/image/similarity/').to_return(body: { 'success': true }.to_json)
    WebMock.stub_request(:post, 'http://localhost:3100/image/classification/').with(body: { uri: url}).to_return(body:{ result: @flags }.to_json)
    WebMock.stub_request(:post, 'http://localhost:3100/similarity/async/image').to_return(body: { "result": [] }.to_json)
  end

  # def teardown
  #   puts '$ cat log/alegre_mock_service.log'
  #   path = File.join(Rails.root, 'log', 'alegre_mock_service.log')
  #   puts `cat #{path}`
  # end

  test "should return language" do
    stub_configs({ 'alegre_host' => 'http://localhost:3100' }) do
      alegre.given('a text exists').
      upon_receiving('a request to identify its language').
      with(
        method: :post,
        path: '/text/langid/',
        headers: {'Content-Type' => 'application/json'},
        body: {text: 'This is a test'}
      ).
      will_respond_with(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: { result: { language: 'en', confidence: 1 }, raw: [{ confidence: 1, language: 'en', input: 'This is a test' }], provider: 'google' }
      )
      assert_equal 'en', Bot::Alegre.get_language_from_alegre('This is a test')
    end
  end

  test "should get image flags" do
    stub_configs({ 'alegre_host' => 'http://localhost:3100' }) do
      WebMock.stub_request(:post, 'http://localhost:3100/image/ocr/').with({ body: { url: @url } }).to_return(body: { "text": @extracted_text  }.to_json)
      Bot::Alegre.unstub(:media_file_url)
      alegre.given('an image URL').
      upon_receiving('a request to get image flags').
      with(
        method: :post,
        path: '/image/classification/',
        body: { uri: @url },
        ).
        will_respond_with(
          status: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: { result: @flags }
        )
      pm1 = create_project_media team: @pm.team, media: create_uploaded_image
      stub_similarity_requests(@url2, pm1)
      Bot::Alegre.stubs(:media_file_url).with(pm1).returns(@url)
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      assert_not_nil pm1.get_annotations('flag').last
      Bot::Alegre.unstub(:media_file_url)
    end
  end

  test "should extract text" do
    stub_configs({ 'alegre_host' => 'http://localhost:3100' }) do
      WebMock.stub_request(:post, 'http://localhost:3100/text/similarity/search/').to_return(body: {success: true}.to_json)
      Bot::Alegre.unstub(:media_file_url)
      alegre.given('an image URL').
      upon_receiving('a request to extract text').
      with(
        method: :post,
        path: '/image/ocr/',
        body: { url: @url }
      ).
      will_respond_with(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: { text: @extracted_text },
      )
      pm2 = create_project_media team: @pm.team, media: create_uploaded_image
      stub_similarity_requests(@url, pm2)
      Bot::Alegre.stubs(:media_file_url).with(pm2).returns(@url)
      assert Bot::Alegre.run({ data: { dbid: pm2.id }, event: 'create_project_media' })
      extracted_text_annotation = pm2.get_annotations('extracted_text').last
      assert_equal @extracted_text, extracted_text_annotation.data['text']
      Bot::Alegre.unstub(:media_file_url)
    end
  end
end
