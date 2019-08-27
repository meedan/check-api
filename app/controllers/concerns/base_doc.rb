# :nocov:
module BaseDoc
  extend ActiveSupport::Concern

  included do
    swagger_controller '/', 'BaseApi'

    swagger_api :version do
      summary 'Get current version'
      notes 'Use this method in order to get the current version of this application'
      # param :query, :text, :string, :required, 'Text to be classified'
      # response(code, message, exampleRequest)
      # "exampleRequest" should be: { query: {}, headers: {}, body: {} }
      authed = { CONFIG['authorization_header'] => 'test' }
      response :ok, 'The version of this application', { query: {}, headers: authed }
      response 401, 'Access denied', { query: {} }
    end

    swagger_api :me do
      summary 'Information about current user'
      notes 'Use this method in order to get information about current user, either by session or token'
      # param :query, :text, :string, :required, 'Text to be classified'
      # response(code, message, exampleRequest)
      # "exampleRequest" should be: { query: {}, headers: {}, body: {} }
      response :ok, 'Information about current user, or nil if not authenticated', {}
    end
  end
end
# :nocov:
