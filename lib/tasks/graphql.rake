namespace :lapis do
  namespace :graphql do
    task update_schema_json: :environment do
      path = File.join(Rails.root, 'public', 'relay.json')
      File.open(path, 'w+') do |f|
        f.write(RelayOnRailsSchema.execute(GraphQL::Introspection::INTROSPECTION_QUERY).to_json)
      end
      puts "Check your GraphQL/Relay schema at #{path}"
    end

    task docs: :environment do
      path = File.join(Rails.root, 'doc', 'graphql.md')
      f = File.open(path, 'w+')
      f.puts('# GraphQL Documentation')
      f.puts
      f.puts('You can test the GraphQL endpoint by going to `/graphiql`. The available actions are:')
      f.puts
      f.close
      `DOCUMENT=true ruby #{File.join(Rails.root, 'test', 'controllers', 'graphql_controller_test.rb')} 2>&1 >/dev/null`
      puts "Check your GraphQL documentation (in Markdown format) at #{path}"
    end
  end
end
