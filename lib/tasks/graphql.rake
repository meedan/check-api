namespace :lapis do
  namespace :graphql do
    task schema: :environment do
      require "graphql/rake_task"

      GraphQL::RakeTask.new(
        load_schema: ->(_task) {
          require File.expand_path("../../config/environment", __dir__)
          RelayOnRailsSchema
        },
        directory: "./public",
        json_outfile: "relay.json"
      )
      Rake::Task["graphql:schema:json"].invoke
    end
  end
end
