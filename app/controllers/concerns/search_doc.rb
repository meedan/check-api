# :nocov:
module SearchDoc
  extend ActiveSupport::Concern

  included do
    swagger_controller :search, 'Search'

    swagger_api :create do
      summary 'Search interface'
      notes 'Use this method in order to send queries to the ES server'
      param :query, :query, :string, :required, 'Search query'
      # response(code, message, exampleRequest)
      # "exampleRequest" should be: { query: {}, headers: {}, body: {} }
      authed = { CONFIG['authorization_header'] => 'test' }
      response :ok, 'Search result', { query: { query: 'query Query { about { name, version } }' }, headers: authed }
      response 401, 'Access denied', { query: { query: 'query Query { about { name, version } }' } }
    end
  end
end
# :nocov:
