namespace :lapis do
  namespace :client do
    task ruby: :environment do
      # Work with test environment
      ActiveRecord::Base.establish_connection('test')
      ApiKey.where(access_token: 'test').destroy_all
      api_key = ApiKey.create!
      api_key.access_token = 'test'
      api_key.save!

      # Generate name
      camel_name = Rails.application.class.to_s.gsub(/::Application$/, '')
      gem_camel_name = "#{camel_name}Client"
      snake_name = camel_name.underscore
      gem_snake_name = "#{snake_name}_client"

      # Get current version number
      basedir = File.join(gem_snake_name, 'lib', gem_snake_name)
      version_file = File.join(basedir, 'version.rb')
      current_version = '0.1.0'
      new_version = '0.0.1'
      if File.exists?(version_file)
        number = File.readlines(version_file)[1].gsub(/[^0-9\.]/, '').gsub('0.0.', '').to_i
        new_version = '0.0.' + (number + 1).to_s
      end

      # Remove current gem if it exists
      FileUtils.rm_rf(gem_snake_name)

      # Create new gem
      system "bundle gem #{gem_snake_name} --mit"

      # Update version number
      content = File.read(version_file).gsub(current_version, new_version)
      f = File.open(version_file, 'w+')
      f.puts(content)
      f.close

      # Update license
      license = File.join(gem_snake_name, 'LICENSE.txt')
      content = File.read(license)
      content.gsub!(/(Copyright \(c\) #{Time.now.year} ).*\n/, "\\1#{INFO[:author]}\n")
      f = File.open(license, 'w+')
      f.puts(content)
      f.close

      # Parse each possible return (from Swagger)
      mock_methods = []
      mock_methods_sigs = []
      request_methods = []
      request_methods_sigs = []
      version = Swagger::Docs::Config.registered_apis.keys.last
      docs = Swagger::Docs::Generator.generate_docs(Swagger::Docs::Config.registered_apis)[version][:processed]

      docs.each do |doc|
       doc[:apis].each do |api|

         api[:path].gsub!(/^\//, '')

         path = api[:path].gsub(/^api\//, '').gsub('/', '_')

         api[:operations].each do |op|

           next if op[:response_messages].first[:responseModel].nil?

           apicall = "#{op[:method].upcase} /#{api[:path]}"
           method = "#{op[:method]}_#{path}"
           request_methods_sigs << "#{method} (`#{apicall}`)"

           request_methods << %{
    # #{apicall}
    def self.#{method}(host = nil, params = {}, token = '', headers = {})
      request('#{op[:method]}', host, '/#{api[:path]}', params, token, headers)
    end
           }

           op[:response_messages].each do |r|

             status = r[:code]
             status == :ok if status == :success
             status = Rack::Utils.status_code(status)

             mock_method = "mock_#{path}_returns_#{r[:message].parameterize.gsub('-', '_')}"
             mock_methods_sigs << mock_method
             example = r[:responseModel]
             app = ActionDispatch::Integration::Session.new(Rails.application)
             response = app.send(op[:method], '/' + api[:path], example[:query], example[:headers])
             json = app.body.chomp
             object = nil
             begin
               object = JSON.parse(json)
             rescue
             end

             mock_methods << %{
    def self.#{mock_method}(host = nil)
      WebMock.disable_net_connect!
      host ||= #{gem_camel_name}.host
      WebMock.stub_request(:#{op[:method]}, host + '/#{api[:path]}')
      .with(#{example})
      .to_return(body: '#{json}', status: #{status})
      @data = #{object.inspect}
      yield
      WebMock.allow_net_connect!
    end
             }

           end
         end
       end
      end

      # Get exposed functions

      require 'rdoc'
      require 'htmlentities'
      exposed_methods_signs = []
      exposed_methods_bodies = []
      exposed_gems = []
      rdoc = RDoc::RDoc.new
      options = rdoc.load_options
      rdoc.options = options
      rdoc.store = RDoc::Store.new
      classes = rdoc.parse_files(['app', 'lib'])[0].instance_variable_get('@store').all_classes
      classes.each do |c|
        c.method_list.each do |m|
          dump = m.marshal_dump
          tags = dump[5].parts.map(&:parts).flatten
          if tags.include?('@expose')
            exposed_methods_signs << dump[1]
            body = HTMLEntities.new.decode(m.markup_code.gsub(/<span class=\"ruby-comment\">.*<\/span>/, '').gsub(/<[^>]*>/, '').gsub("\n", "\n    ").gsub(/ def /, ' def self.'))
            exposed_gems += body.scan(/\srequire ['"]([^'"]+)['"]/).flatten 
            exposed_methods_bodies << body
          end
        end
      end

      # Update spec (metadata and dependencies)
      specfile = File.join(gem_snake_name, "#{gem_snake_name}.gemspec")
      content = File.read(specfile)
      content.gsub!(/spec\.authors.*\n/, "spec.authors = ['#{INFO[:author]}']\n")
      content.gsub!(/spec\.email.*\n/, "spec.email = ['#{INFO[:author_email]}']\n")
      content.gsub!(/spec\.summary.*\n/, "spec.summary = ['#{INFO[:description]} (Client)']\n")
      content.gsub!(/spec\.description.*\n/, "spec.description = ['#{INFO[:description]} (Client)']\n")
      content.gsub!(/^end$/, "  spec.add_development_dependency \"webmock\", \"~> 1.21.0\"\nend")
      exposed_gems.each do |dep|
        content.gsub!(/^end$/, "  spec.add_runtime_dependency \"#{dep}\"\nend")
      end
      f = File.open(specfile, 'w+')
      f.puts(content)
      f.close

      # Update README
      readme = %{
# #{gem_camel_name}

This gem is a client for #{snake_name}, which defines itself as '#{INFO[:description]}'. It also provides mock methods to test it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem '#{gem_snake_name}'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install #{gem_snake_name}

## Usage

With this gem you can call methods from #{snake_name}'s API and also test them by using the provided mocks.

The available methods are:

#{request_methods_sigs.collect{ |r| "* #{gem_camel_name}::Request.#{r}" }.join("\n")}

If you are going to test something that uses the '#{gem_snake_name}' service, first you need to mock each possible response it can return, which are:

#{mock_methods_sigs.collect{ |r| "* #{gem_camel_name}::Mock.#{r}" }.join("\n")}

You can also reuse utility functions that are exposed by '#{gem_snake_name}'. They are:

#{exposed_methods_signs.collect{ |r| "* #{gem_camel_name}::Util.#{r}" }.join("\n")}

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
      }
      f = File.open(File.join(gem_snake_name, 'README.md'), 'w+')
      f.puts(readme)
      f.close

      # Now the important stuff - generate the library
      lib = %{require '#{gem_snake_name}/version'
require 'webmock'
require 'net/http'
module #{gem_camel_name}
  include WebMock::API

  @host = nil

  def self.host=(host)
    @host = host
  end

  def self.host
    @host
  end

  module Request
    #{request_methods.join}
    private

    def self.request(method, host, path, params = {}, token = '', headers = {})
      host ||= #{gem_camel_name}.host
      uri = URI(host + path)
      klass = 'Net::HTTP::' + method.capitalize
      request = nil

      if method == 'get'
        querystr = params.reject{ |k, v| v.blank? }.collect{ |k, v| k.to_s + '=' + CGI::escape(v.to_s) }.reverse.join('&')
        (querystr = '?' + querystr) unless querystr.blank?
        request = klass.constantize.new(uri.path + querystr)
      elsif method == 'post'
        request = klass.constantize.new(uri.path)
        request.set_form_data(params)
      end

      unless token.blank?
        request['#{CONFIG['authorization_header'] || 'X-Token'}'] = token.to_s
      end

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'
      response = http.request(request)
      if response.code.to_i === 401
        raise 'Unauthorized'
      else
        JSON.parse(response.body)
      end
    end
  end

  module Mock
    #{mock_methods.join}
  end

  module Util
    #{exposed_methods_bodies.join}
  end
end}
      f = File.open(File.join(gem_snake_name, 'lib', "#{gem_snake_name}.rb"), 'w+')
      f.puts(lib)
      f.close

      # Compile gem
      system "cd #{gem_snake_name} && gem build #{gem_snake_name}.gemspec && cd .."

      # Finish
      puts
      puts '----------------------------------------------------------------------------------------------------------------'
      puts "Done! Your gem is at '#{gem_snake_name}'. Now please submit it to a remote Github repository."
      puts "After that, add the repository address in line 14 ('homepage') of file #{gem_snake_name}/#{gem_snake_name}.gemspec."
      puts "Or publish to RubyGems.org and add that URL."
      puts '----------------------------------------------------------------------------------------------------------------'

      api_key.destroy!
      ActiveRecord::Base.establish_connection(ENV['RAILS_ENV'])
    end
  end
end
