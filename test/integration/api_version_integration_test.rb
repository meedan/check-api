require_relative '../test_helper'

class ApiVersionIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    super
  end

  test "should get version" do
    assert_recognizes({ controller: 'api/v1/base_api', action: 'version', format: 'json' }, { path: 'api/version', method: :get })
  end

  test "should post log" do
    assert_recognizes({ controller: 'api/v1/base_api', action: 'log', format: 'json' }, { path: 'api/log', method: :post })
  end
end
