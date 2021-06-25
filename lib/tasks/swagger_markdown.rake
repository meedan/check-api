namespace :swagger do
  namespace :docs do
    task markdown: :environment do
      # Work with test environment
      ApplicationRecord.establish_connection('test')
      ApiKey.where(access_token: 'test').destroy_all
      api_key = ApiKey.create!
      api_key.access_token = 'test'
      api_key.save!

      # Output to a markdown file
      output = File.open(File.join(Rails.root, 'doc', 'api.md'), 'w+')
      output.puts("### API")

      # Parse each possible return (from Swagger)
      version = Swagger::Docs::Config.registered_apis.keys.last
      docs = Swagger::Docs::Generator.generate_docs(Swagger::Docs::Config.registered_apis)[version][:processed]

      puts JSON.pretty_generate(docs)

      docs.each do |doc|
        doc[:apis].each do |api|

          api[:path].gsub!(/^\//, '')

          api[:operations].each do |op|

            next if op[:response_messages].first[:responseModel].nil?

            apicall = "#{op[:method].upcase} /#{api[:path]}"

            output.puts
            output.puts("#### #{apicall}")
            output.puts
            output.puts("#{op[:notes]}")
            output.puts
            output.puts("**Parameters**")
            output.puts

            op[:parameters] ||= []
            op[:parameters].each do |p|
              required = p[:required] ? ' _(required)_' : ''
              output.puts("* `#{p[:name]}`: #{p[:description]}#{required}")
            end
            output.puts

            output.puts("**Response**")
            output.puts

            op[:response_messages].each do |r|
              example = r[:responseModel]

              output.puts "#{r[:code]}: #{r[:message]}"

              app = ActionDispatch::Integration::Session.new(Rails.application)
              response = app.send(op[:method], '/' + api[:path], example[:query], example[:headers])
              json = app.body.chomp
              object = nil

              begin
                object = JSON.parse(json)
                output.puts('```json')
                output.puts JSON.pretty_generate(object)
                output.puts('```')
              rescue
              end # rescue

              output.puts
            end # response message
          end # operations
        end # api
      end # docs

      output.close

      api_key.destroy!
      ApplicationRecord.establish_connection(ENV['RAILS_ENV'])

      puts "Done! Check your API documentation at doc/api.md. You can copy and paste it to your README.md."
    end # task
  end # namespace
end # namespace
