# In /spec/service_providers/pact_helper.rb
require_relative '../../test_helper'
# require 'pact/consumer/rspec'
require 'pact/consumer/minitest'
Pact.service_consumer "Check API" do
  has_pact_with "Alegre" do
    mock_service :alegre do
      port 5000
    end
  end
end