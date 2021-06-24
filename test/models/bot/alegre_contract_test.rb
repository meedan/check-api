require_relative 'pact_helper'

class Bot::AlegreContractTest < ActiveSupport::TestCase
  include Pact::Consumer::Minitest

  def setup
    # stub_request(:any, "http://localhost:5000/pact")
    p = create_project
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media project: p, media: m
  end

  def teardown
    puts '$ cat log/alegre_mock_service.log'
    path = File.join(Rails.root, 'log', 'alegre_mock_service.log')
    puts `cat #{path}`
  end

  test 'should return language' do
    stub_configs({ 'alegre_host' => 'http://localhost:5000' }) do
      alegre.given('a text exists').
      upon_receiving('a request to identify its language').
      with(
        method: :get,
        path: '/text/langid/',
        body: { text: 'This is a test' },
        headers: {
          'Content-Type': 'application/json'
        }
      ).
      will_respond_with(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: { result: { language: 'en', confidence: 0.421875 }, raw: [{ confidence: 0.421875, language: 'en', input: 'This is a test' }], provider: 'google' }.to_json
      )
      assert_equal 'en', Bot::Alegre.get_language_from_alegre('This is a test')
    end
  end

  test "should get image flags" do
    stub_configs({ 'alegre_host' => 'http://localhost:5000' }) do
      WebMock.stub_request(:post, 'http://localhost:5000/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://localhost:5000/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://localhost:5000/image/similarity/').to_return(body: {
        "success": true
      }.to_json)
      WebMock.stub_request(:get, 'http://localhost:5000/image/similarity/').to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:get, 'http://localhost:5000/image/ocr/').to_return(body: {
        "text": "Foo bar"
      }.to_json)
      WebMock.stub_request(:post, 'http://localhost:5000/image/similarity/').to_return(body: 'success')
      Bot::Alegre.unstub(:media_file_url)
      alegre.given('an image URL').
      upon_receiving('a request to get image flags').
      with(
        method: :get,
        path: '/image/classification/',
        body: { uri: 'https://i.imgur.com/ewGClFQ.png' },
        headers: {
          'Content-Type': 'application/json'
        }
      ).
      will_respond_with(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: { result: valid_flags_data }
      )
      pm1 = create_project_media team: @pm.team, media: create_uploaded_image
      Bot::Alegre.stubs(:media_file_url).with(pm1).returns("https://i.imgur.com/ewGClFQ.png")
      # puts" pm1.get_annotations('flag').last #{pm1.get_annotations('flag').last}" 
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      Bot::Alegre.unstub(:media_file_url)
    end
  end

end