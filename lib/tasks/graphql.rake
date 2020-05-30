namespace :lapis do
  namespace :graphql do
    task schema: :environment do
      path = File.join(Rails.root, 'public', 'relay.json')
      File.open(path, 'w+') do |f|
        f.write(JSON.generate(RelayOnRailsSchema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)))
      end
      puts "Check your GraphQL/Relay schema at #{path}"
    end
  end
end
