require_relative 'pact_helper'

class Bot::AlegreContractTest < ActiveSupport::TestCase
  include Pact::Consumer::Minitest

  def setup
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
  end

  def teardown
    puts '$ cat log/alegre_mock_service.log'
    path = File.join(Rails.root, 'log', 'alegre_mock_service.log')
    puts `cat #{path}`
  end

  test 'returns language' do
    stub_configs({ 'alegre_host' => 'http://localhost:5000' }) do
      assert_equal 'en', Bot::Alegre.get_language_from_alegre('This is a test')
    end
  end
end
