# In /spec/service_providers/animal_service_client_spec.rb
# When using RSpec, use the metadata `:pact => true` to include all the pact functionality in your spec.
# When using Minitest, include Pact::Consumer::Minitest in your spec.
require_relative '../../test_helper'
require_relative 'pact_helper'
class Bot::AlegreContractTest < ActiveSupport::TestCase
  include Pact::Consumer::Minitest
  def setup
    super
    alegre.given("the first request").
      upon_receiving("pastel").
      with(
        method: :get,
        path: '/text/langid/',
        ).
      will_respond_with(
        status: 200,
        body: {"result": {'language': 'en'}}.to_json
      )
  end
  test "returns language" do
    assert_equal 'en', Bot::Alegre.get_language_from_alegre('pastel')
  end
end