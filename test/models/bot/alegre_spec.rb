require_relative '../../test_helper'
require_relative '../../../lib/sample_data'
require 'rails/test_help'
require 'rspec/rails'
require 'pact/consumer/rspec'
require_relative 'pact_helper'

describe 'test', :pact => true do
  before do
    alegre.given("Alegre returns text language").
      upon_receiving("a text").
      with(
        method: :get,
        path: '/text/langid/',
        headers: {'Content-Type' => 'application/json'}
        ).
      will_respond_with(
        status: 200,
        headers: {'Content-Type' => 'application/json'},
        body: {"result": {'language': 'en'}}.to_json
      )
  end

  it "should get language" do
    puts "pastel"
    assert_equal 'en', Bot::Alegre.get_language_from_alegre('pastel')
  end
end