namespace :lapis do
  namespace :graphql do
    task schema: :environment do
      path = File.join(Rails.root, 'public', 'relay.json')
      File.open(path, 'w+') do |f|
        f.write(JSON.pretty_generate(RelayOnRailsSchema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)))
      end
      puts "Check your GraphQL/Relay schema at #{path}"
    end

    task docs: :environment do
      dir = File.join(Rails.root, 'doc', 'graphql')
      FileUtils.rm_rf(dir)
      FileUtils.mkdir_p(dir)
      path = File.join(Rails.root, 'doc', 'graphql.md')
      f = File.open(path, 'w+')
      f.puts
      f.close
      header = <<-eos
# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:
      eos
      `DOCUMENT=true ruby #{File.join(Rails.root, 'test', 'controllers', 'graphql_controller_test.rb')} 2>&1 >/dev/null`
      `cat #{dir}/* > /tmp/graphql.md`
      `echo '#{header}' > #{path} && gh-md-toc /tmp/graphql.md | grep '\*' | sed 's/^    //g' >> #{path} && cat /tmp/graphql.md >> #{path} && rm -f /tmp/graphql`
      FileUtils.rm_rf(dir)
      puts "Check your GraphQL documentation (in Markdown format) at #{path}"
    end
  end
end
