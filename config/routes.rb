require 'api_constraints'

Rails.application.routes.draw do
  resources :sources
  resources :teams
  resources :users
  resources :accounts
  resources :media
  resources :projects
  namespace :api, defaults: { format: 'json' } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      get 'version', to: 'base_api#version'
      get 'me', to: 'base_api#me'
      scope '/graphql' do
        match '/' => 'graphql#create', via: [:post]
        match '/' => 'graphql#options', via: [:options]
      end
      devise_for :users, controllers: { sessions: nil, registrations: nil, omniauth_callbacks: 'api/v1/omniauth_callbacks' },
                         skip: [:registrations, :sessions]
    end
  end
end
