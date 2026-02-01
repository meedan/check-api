require 'api_constraints'
require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/graphql'
  mount Sidekiq::Web => '/sidekiq'

  namespace :api, defaults: { format: 'json' } do
    # Call v2 API by passing header: 'Accept: application/vnd.api+json'
    scope module: :v2, constraints: ApiConstraints.new(version: 2, default: false) do
      match '/options' => 'base_api#options', via: [:options]
      get 'version', to: 'base_api#version'
      get 'ping', to: 'base_api#ping'

      scope :v2 do
        jsonapi_resources :feeds, only: [:index]
      end
    end
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
      match '/admin/user/slack' => 'admin#slack_user', via: [:get]
      match '/admin/smooch_bot/:id/authorize/twitter' => 'admin#save_twitter_credentials_for_smooch_bot', via: [:get]
      match '/admin/smooch_bot/:id/authorize/messenger' => 'admin#save_messenger_credentials_for_smooch_bot', via: [:get]
      match '/admin/smooch_bot/:id/authorize/instagram' => 'admin#save_instagram_credentials_for_smooch_bot', via: [:get]
      match '/project_medias/:id/oembed' => 'project_medias#oembed', via: [:get], defaults: { format: :json }
      match '/webhooks/:name' => 'webhooks#index', via: [:post, :get], defaults: { format: :json }
      devise_for :users, controllers: { invitations: 'api/v1/invitations', sessions: 'api/v1/sessions', omniauth_callbacks: 'api/v1/omniauth_callbacks', confirmations: 'api/v1/confirmations' }
      devise_scope :api_user do
        get '/users/logout', to: 'omniauth_callbacks#logout'
        get '/users/auth/facebook/setup' => 'omniauth_callbacks#setup'
      end
    end
  end

  # Short URLs (powered by https://github.com/jpmcgrath/shortener)
  if CheckConfig.get('short_url_host')
    constraints host: URI.parse(CheckConfig.get('short_url_host')).host do
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
  match '/test/update_tag_texts' => 'test#update_tag_texts', via: :get
  match '/test/media_status' => 'test#media_status', via: :get
  match '/test/new_media_tag' => 'test#new_media_tag', via: :get
  match '/test/new_task' => 'test#new_task', via: :get
  match '/test/new_api_key' => 'test#new_api_key', via: :get
  match '/test/bot' => 'test#new_bot', via: :get
  match '/test/get' => 'test#get', via: :get
  match '/test/archive_project' => 'test#archive_project', via: :get
  match '/test/dynamic_annotation' => 'test#new_dynamic_annotation', via: :get
  match '/test/cache_key' => 'test#new_cache_key', via: :get
  match '/test/team_data_field' => 'test#new_team_data_field', via: :get
  match '/test/suggest_similarity' => 'test#suggest_similarity_item', via: :get
  match '/test/install_bot' => 'test#install_bot', via: :get
  match '/test/add_team_user' => 'test#add_team_user', via: :get
  match '/test/create_imported_standalone_fact_check' => 'test#create_imported_standalone_fact_check', via: :get
  match '/test/create_saved_search_list' => 'test#create_saved_search_list', via: :get
  match '/test/create_feed_with_item' => 'test#create_feed_with_item', via: :get
  match '/test/create_feed_invitation' => 'test#create_feed_invitation', via: :get
  match '/test/random' => 'test#random', via: :get
end
