require_relative '../test_helper'
require 'pact/consumer/minitest'

Pact.service_consumer "Check API" do
  has_pact_with "Alegre" do
    mock_service :alegre do
      port 3100
    end
  end
end
