namespace :jsonapi do
  namespace :resources do
    desc 'Generates schema file for the JSON:API v2 API. Schema file is required by some clients, such as https://github.com/aribouius/jsonapi-react (FIXME: Need to generate relationships too)'
    task :update_schema do
      schema = {}
      Dir.glob(File.join(Rails.root, 'app', 'resources', 'api', 'v2', '*')).each do |resource_file|
        name = File.basename(resource_file, '.*').gsub(/_resource$/, '')
        next if name == 'base'
        plural = name.pluralize.to_sym
        schema[plural] = { type: plural }
      end
      path = File.join(Rails.root, 'public', 'jsonapischema.json')
      output = File.open(path, 'w+')
      output.puts schema.to_json
      output.close
      puts "JSON:API schema generated at #{path}"
    end
  end
end
