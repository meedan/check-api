# :nocov:
module SessionsDoc
  extend ActiveSupport::Concern

  included do
    swagger_controller :sessions, 'Sessions'

    swagger_api :create do
      summary 'Sign in'
      notes 'Use this method in order to sign in'
      param :query, 'api_user[email]', :string, :required, 'E-mail'
      param :query, 'api_user[password]', :string, :required, 'Password'

      query = { api_user: { password: '12345678', email: 't@test.com' } }
      response :ok, 'Signed in', { query: query }
      response 401, 'Could not sign in', { query: query.merge({ password: '12345679' }) }
    end

    swagger_api :destroy do
      summary 'Sign out'
      notes 'Use this method in order to sign out'

      response :ok, 'Signed out', { query: {} }
    end
  end
end
# :nocov:
