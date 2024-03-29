# :nocov:
module RegistrationsDoc
  extend ActiveSupport::Concern

  included do
    swagger_controller :registrations, 'Registrations'

    swagger_api :create do
      summary 'Create users'
      notes 'Use this method in order to create a new user account'
      param :query, 'api_user[email]', :string, :required, 'E-mail'
      param :query, 'api_user[name]', :string, :required, 'Name'
      param :query, 'api_user[password]', :string, :required, 'Password'
      param :query, 'api_user[password_confirmation]', :string, :required, 'Password Confirmation'

      query = { password: '12345678', password_confirmation: '12345678', name: 'Test' }
      response :ok, 'Account created', { query: { api_user: query.merge(email: "t_#{rand(100)}@test.com") }}
      response 400, 'Password is too short', { query: { api_user: query.merge({ password: '123456', password_confirmation: '123456', email: "t_#{rand(100)}@test.com" })}}
      response 400, 'Passwords do not match', { query: { api_user: query.merge({ password_confirmation: '12345679', email: "t_#{rand(100)}@test.com" })}}
      response 400, 'E-mail missing', { query: { api_user: query.merge({ email: '' })}}
      response 400, 'Password is missing', { query: { api_user: query.merge({ password: '', password_confirmation: '', email: "t_#{rand(100)}@test.com" })}}
      response 400, 'Name is missing', { query: { api_user: query.merge({ name: '', email: "t_#{rand(100)}@test.com" })}}
    end

    # TODO Missing authentication to be able to update the user
    swagger_api :update do
      summary 'Update users'
      notes 'Use this method in order to update your account'
      param :query, 'api_user[email]', :string, :optional, 'E-mail'
      param :query, 'api_user[name]', :string, :optional, 'Name'
      param :query, 'api_user[password]', :string, :optional, 'Password'
      param :query, 'api_user[password_confirmation]', :string, :optional, 'Password Confirmation'
      param :query, 'api_user[current_password]', :string, :optional, 'Current Password'


      query = { password: '12345678', password_confirmation: '12345678', name: 'Test' }
      response :ok, 'Account updated', { query: { api_user: query.merge(email: "t_#{rand(100)}@test.com") }}
      response 400, 'Password is too short', { query: { api_user: query.merge({ password: '123456', password_confirmation: '123456', email: "t_#{rand(100)}@test.com" })}}
      response 400, 'Passwords do not match', { query: { api_user: query.merge({ password_confirmation: '12345679', email: "t_#{rand(100)}@test.com" })}}
      response 400, 'E-mail missing', { query: { api_user: query.merge({ email: '' })}}
      response 400, 'Password is missing', { query: { api_user: query.merge({ password: '', password_confirmation: '', email: "t_#{rand(100)}@test.com" })}}
      response 400, 'Name is missing', { query: { api_user: query.merge({ name: '', email: "t_#{rand(100)}@test.com" })}}

    end

    swagger_api :destroy do
      summary 'Delete users'
      notes 'Use this method in order to delete your account'

      response :ok, 'Account deleted', { query: {} }
    end
  end
end
# :nocov:
