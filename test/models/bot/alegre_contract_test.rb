require_relative 'pact_helper'

class Bot::AlegreContractTest < ActiveSupport::TestCase
  include Pact::Consumer::Minitest

  def setup
    stub_request(:any, "http://localhost:5000/pact")
    stub_request(:get, "http://localhost:5000/interactions/verification?example_description=Bot::AlegreContractTest")
  end

  def teardown
    puts '$ cat log/alegre_mock_service.log'
    path = File.join(Rails.root, 'log', 'alegre_mock_service.log')
    puts `cat #{path}`
  end

  test 'should return language' do
    stub_configs({ 'alegre_host' => 'http://localhost:5000' }) do
      Bot::Alegre.stubs(:request_api).returns({
        'result' => {
          'language' => 'en',
          'confidence' => 1.0
        }
      })
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
    Bot::Alegre.unstub(:request_api)
  end

  test 'should return language und if there is an error' do
    stub_configs({ 'alegre_host' => 'http://localhost:5000' }) do
      Bot::Alegre.stubs(:request_api).raises(RuntimeError)
      alegre.given('a text exists').
      upon_receiving('a request with an error').
      with(
        method: :get,
        path: '/text/langid/',
        body: { 'foo': 'bar' },
        headers: {
          'Content-Type': 'application/json'
        }
      ).
      will_respond_with(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        }
        # body: { result: { language: 'en', confidence: 0.421875 }}.to_json
      )
      assert_equal 'und', Bot::Alegre.get_language_from_alegre('This is a test')
    end
    Bot::Alegre.unstub(:request_api)
  end

end