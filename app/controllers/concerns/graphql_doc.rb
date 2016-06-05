# :nocov:
module GraphqlDoc
  extend ActiveSupport::Concern
 
  included do
    swagger_controller :graphql, 'GraphQL'

    swagger_api :create do
      summary 'GraphQL interface'
      notes 'Use this method in order to send queries to the GraphQL server'
      param :query, :query, :string, :required, 'GraphQL query'
      # response(code, message, exampleRequest)
      # "exampleRequest" should be: { query: {}, headers: {}, body: {} }
      authed = { CONFIG['authorization_header'] => 'test' }
      response :ok, 'GraphQL result', { query: { query: 'query Query { about { name, version } }' }, headers: authed }
      response 401, 'Access denied', { query: { query: 'query Query { about { name, version } }' } }
    end
  end
end
# :nocov:
