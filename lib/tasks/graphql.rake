namespace :lapis do
  namespace :graphql do
    task schema: :environment do
      require "graphql/rake_task"
      require 'fileutils'

      GraphQL::RakeTask.new(
        load_schema: ->(_task) {
            require File.expand_path("../../config/environment", __dir__)
            RelayOnRailsSchema
          },
          directory: "./tmp",
          json_outfile: "relay.json",
          idl_outfile: "relay.idl"
        )
      Rake::Task["graphql:schema:dump"].invoke

      puts "Moving tmp/relay.json to public/relay.json"
      FileUtils.mv('./tmp/relay.json', './public/relay.json')

      puts "Moving tmp/relay.idl to lib/relay.idl"
      FileUtils.mv('./tmp/relay.idl', './lib/relay.idl')
    end
  end
end
