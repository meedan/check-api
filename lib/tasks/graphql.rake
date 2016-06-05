namespace :lapis do
  namespace :graphql do
    task update_schema_json: :environment do
      path = File.join(Rails.root, 'public', 'relay.json')
      File.open(path, 'w+') do |f|
        f.write(RelayOnRailsSchema.execute(GraphQL::Introspection::INTROSPECTION_QUERY).to_json)
      end
      puts "Check your GraphQL/Relay schema at #{path}"
    end
  end
end
