require 'api_constraints'
require 'sidekiq/web'

Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
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
      match '/admin/project/:id/add_publisher/:provider' => 'admin#add_publisher_to_project', via: [:get]
      match '/admin/user/slack' => 'admin#slack_user', via: [:get]
      match '/project_medias/:id/oembed' => 'project_medias#oembed', via: [:get], defaults: { format: :json }
      match '/project_medias/webhook' => 'project_medias#webhook', via: [:post], defaults: { format: :json }
      devise_for :users, controllers: { sessions: 'api/v1/sessions', registrations: 'api/v1/registrations', omniauth_callbacks: 'api/v1/omniauth_callbacks', confirmations: 'api/v1/confirmations' }
      devise_scope :api_user do
        get '/users/logout', to: 'omniauth_callbacks#logout'
      end
    end
  end

  match '/test/confirm_user' => 'test#confirm_user', via: :get
  match '/test/make_team_public' => 'test#make_team_public', via: :get
  match '/test/user' => 'test#new_user', via: :get
  match '/test/team' => 'test#new_team', via: :get
  match '/test/create_team_project_and_two_users' => 'test#create_team_project_and_two_users', via: :get
  match '/test/project' => 'test#new_project', via: :get
  match '/test/session' => 'test#new_session', via: :get
  match '/test/claim' => 'test#new_claim', via: :get
  match '/test/link' => 'test#new_link', via: :get
  match '/test/source' => 'test#new_source', via: :get
  match '/test/update_suggested_tags' => 'test#update_suggested_tags', via: :get
  match '/test/media_status' => 'test#media_status', via: :get
  match '/test/new_media_tag' => 'test#new_media_tag', via: :get

end
