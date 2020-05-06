require 'api_constraints'
require 'sidekiq/web'

Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/graphql'

  authenticate :api_user, -> (user) { user.is_admin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  if CONFIG['pg_hero_enabled']
    authenticate :api_user, -> (user) { user.is_admin } do
      mount PgHero::Engine, at: 'pghero'
    end
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
      scope ':pattern', constraints: { pattern: /me|graphql|graphql\/batch|users\/sign_out|users\/sign_in|users/ } do
        match '/' => 'base_api#options', via: [:options]
      end
      match '/options' => 'base_api#options', via: [:options]
      get 'version', to: 'base_api#version'
      get 'ping', to: 'base_api#ping'
      post 'log', to: 'base_api#log'
      match '/me' => 'base_api#me', via: [:get]
      match '/graphql' => 'graphql#create', via: [:post]
      match '/graphql/batch' => 'graphql#batch', via: [:post]
      match '/search' => 'search#create', via: [:post]
      match '/admin/project/:id/add_publisher/:provider' => 'admin#add_publisher_to_project', via: [:get]
      match '/admin/user/slack' => 'admin#slack_user', via: [:get]
      match '/admin/smooch_bot/:id/authorize/twitter' => 'admin#save_twitter_credentials_for_smooch_bot', via: [:get]
      match '/project_medias/:id/oembed' => 'project_medias#oembed', via: [:get], defaults: { format: :json }
      match '/webhooks/:name' => 'webhooks#index', via: [:post], defaults: { format: :json }
      devise_for :users, controllers: { invitations: 'api/v1/invitations', sessions: 'api/v1/sessions', registrations: 'api/v1/registrations', omniauth_callbacks: 'api/v1/omniauth_callbacks', confirmations: 'api/v1/confirmations' }
      devise_scope :api_user do
        get '/users/logout', to: 'omniauth_callbacks#logout'
        get '/users/auth/twitter/setup' => 'omniauth_callbacks#setup'
      end
    end
  end

  # Montage
  namespace :ah, path: '_ah', defaults: { format: 'json' } do
    namespace :api do
      namespace :greenday do
        namespace :v1 do
          match 'ping' => 'base#ping', via: [:get, :options]
          match '/users/me/stats' => 'users#stats', via: [:get, :options]
          match '/users/me' => 'users#me', via: [:get, :options]
          match '/users/nda' => 'users#nda', via: [:post, :options]
          match '/project/:project_id/collection/:collection_id' => 'collections#update', via: [:put, :options]
          match '/project/:project_id/collection/:collection_id' => 'collections#show', via: [:get, :options]
          match '/project/:project_id/collection/:collection_id/add_batch' => 'collections#add_batch', via: [:put, :options]
          match '/project/:id/video/batch-create' => 'projects#batch_create', via: [:put, :options]
          match '/project/:id/video/:youtube_id' => 'projects#show_video', via: [:get, :options]
          match '/project/:id/video/:youtube_id/comments' => 'projects#comments', via: [:get, :post, :options]
          match '/project/:id/video' => 'projects#video', via: [:get, :options]
          match '/project/:id/collection' => 'projects#collection', via: [:get, :post, :options]
          match '/project/:id' => 'projects#show', via: [:get]
          match '/project' => 'projects#create', via: [:post, :options]
          match '/project' => 'projects#index', via: [:get, :options]
        end
      end
    end
  end

  # Short URLs (powered by https://github.com/jpmcgrath/shortener)
  if CONFIG['short_url_host']
    constraints host: URI.parse(CONFIG['short_url_host']).host do
      get '/:id' => 'shortener/shortened_urls#show'
    end
  end

  # Test controller - just works in test mode, used to create data for integration tests (for example, Check Web calls these methods)
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
  match '/test/new_task' => 'test#new_task', via: :get
  match '/test/new_api_key' => 'test#new_api_key', via: :get
  match '/test/bot' => 'test#new_bot', via: :get
  match '/test/get' => 'test#get', via: :get
  match '/test/archive_project' => 'test#archive_project', via: :get
  match '/test/dynamic_annotation' => 'test#new_dynamic_annotation', via: :get
  match '/test/cache_key' => 'test#new_cache_key', via: :get
end
