require 'api_constraints'
require 'sidekiq/web'

Rails.application.routes.draw do
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/graphql'
  if Rails.env.production?
    mount Sidekiq::Web => '/sidekiq'
  end

  # Later, remove from here...
  resources :sources
  resources :teams
  resources :users
  resources :accounts
  resources :medias
  resources :projects
  # ...until here

  namespace :api, defaults: { format: 'json' } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      scope ':pattern', constraints: { pattern: /me|graphql|users\/sign_out|users\/sign_in|users/ } do
        match '/' => 'base_api#options', via: [:options]
      end
      get 'version', to: 'base_api#version'
      match '/me' => 'base_api#me', via: [:get]
      match '/graphql' => 'graphql#create', via: [:post]
      match '/search' => 'search#create', via: [:post]
      devise_for :users, controllers: { sessions: 'api/v1/sessions', registrations: 'api/v1/registrations', omniauth_callbacks: 'api/v1/omniauth_callbacks', confirmations: 'api/v1/confirmations' }
      devise_scope :api_user do
        get '/users/logout', to: 'omniauth_callbacks#logout'
      end
    end
  end

  match '/test/confirm_user' => 'test#confirm_user', via: :get
end
