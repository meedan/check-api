require 'api_constraints'

Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      get 'version', to: 'base_api#version'
      scope '/graphql' do
        match '/' => 'graphql#create', via: [:post]
        match '/' => 'graphql#options', via: [:options]
      end
      # Write your routes here!
    end
  end
end
