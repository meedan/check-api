namespace :lapis do
  namespace :client do
    def recursive_assert(object, root)
      asserts = object.collect{ |k,v| v.is_a?(::Hash) ?
        recursive_assert(v, root + "->" + k) :
        "$this->assertEquals(#{v.inspect}, #{root + '->' + k});" }.join("\n    ")
    end

    task php: :environment do
      # Generate a PHP client package as per
      # http://culttt.com/2014/05/07/create-psr-4-php-package/

      # Generate names
      api_name_camel = Rails.application.class.to_s.gsub(/::Application$/, '')
      api_name_snake = api_name_camel.underscore
      client_name_camel = "#{api_name_camel}Client"
      client_name_snake = "#{api_name_snake}_client"
      client_name_dash = client_name_snake.dasherize
      vendor_name_dash = "#{INFO[:author]}".parameterize
      vendor_name_camel = vendor_name_dash.gsub(/-/, '_').camelize

      # Folder structure and base classes
      basedir = "#{client_name_dash}-php"
      FileUtils.rm_rf(basedir)
      FileUtils.mkdir(basedir)
      srcdir = File.join(basedir, 'src')
      FileUtils.mkdir(srcdir)
      FileUtils.cp('lib/tasks/clients/php/LapisClient.php', srcdir)
      testdir = File.join(basedir, 'tests')
      FileUtils.mkdir(testdir)
      FileUtils.cp('lib/tasks/clients/php/LapisClientTest.php', testdir)
      system "cd #{basedir} && git init"

      # Composer.json
      composer = %{\{
      "name": "#{vendor_name_dash}/#{client_name_dash}",
      "description": "#{INFO[:description]} (Client)",
      "license": "MIT",
      "authors": [
          \{
              "name": "#{INFO[:author]}",
              "email": "#{INFO[:author_email]}"
          \}
      ],
      "require": {
        "guzzlehttp/guzzle": "^6.0",
        "monolog/monolog": "^1.18",
        "rtheunissen/guzzle-log-middleware": "^0.4"
      },
      "require-dev": {
          "phpunit/phpunit": "^5.2"
      },
      "autoload": \{
          "psr-4": \{
              "Meedan\\\\Lapis\\\\": "src",
              "#{vendor_name_camel}\\\\#{client_name_camel}\\\\": "src"
          \}
      \}
  \}}
      f = File.open(File.join(basedir, 'composer.json'), 'w')
      f.puts(composer)
      f.close

      # .gitignore
      gitignore = %{/vendor
  composer.lock}
      f = File.open(File.join(basedir, '.gitignore'), 'w')
      f.puts(gitignore)
      f.close

      # .travis.yml
      travis = %{language: php

  php:
    - 5.4
    - 5.5
    - 5.6
    - hhvm

  before_script:
    - composer self-update
    - composer install --prefer-source --no-interaction --dev

  script: phpunit
      }
      f = File.open(File.join(basedir, '.travis.yml'), 'w')
      f.puts(travis)
      f.close

      # Generate client, mock and test methods
      mock_methods = ''
      mock_methods_sigs = []
      request_methods = ''
      request_methods_sigs = []
      test_methods = ''
      version = Swagger::Docs::Config.registered_apis.keys.last
      docs = Swagger::Docs::Generator.generate_docs(Swagger::Docs::Config.registered_apis)[version][:processed]

      docs.each do |doc|
=begin
{
  :action=>:processed,
  :path=>"api/v1/languages",
  :apis=>[{
    :path=>"/api/languages/classify",
    :operations=>[{
      :summary=>"Send some text to be classified",
      :notes=>"Use this method in order to identify the language of a given text",
      :parameters=>[{
        :param_type=>:query,
        :name=>:text,
        :type=>:string,
        :description=>"Text to be classified",
        :required=>true
      }],
      :response_messages=>[{
        :code=>200,
        :responseModel=>{
          :query=>{
            :text=>"The book is on the table"
          },
          :headers=>{
            "X-Lapis-Example-Token"=>"test"
          }
        },
        :message=>"Text language"
      }, {
        :code=>400,
        :responseModel=>{
          :query=>nil,
          :headers=>{
            "X-Lapis-Example-Token"=>"test"
          }
        },
        :message=>"Parameter \"text\" is missing"
      }, {
        :code=>401,
        :responseModel=>{
          :query=>{
            :text=>"Test"
          }
        },
        :message=>"Access denied"
      }],
      :nickname=>"Api::V1::Languages#classify",
      :method=>:get
    }]
  }],
  :models=>{},
  :klass=>Api::V1::LanguagesController
}
=end
        doc[:apis].each do |api|

          path = api[:path].gsub(/^api\//, '').gsub('/', '_')

          # Generate one method per operation
          api[:operations].each do |op|

            next if op[:response_messages].first[:responseModel].nil?

            endpoint = "#{op[:method].upcase} #{api[:path]}"
            method_name = "#{op[:method]}_#{path}"
            method_args = op[:parameters].collect{ |p| "$#{p[:name]}" }.join(", ")
            method_args_map = op[:parameters].collect{ |p| "'#{p[:name]}' => $#{p[:name]}" }.join(", ")
            method_args_doc = op[:parameters].collect{ |p| "@param $#{p[:name]}\n  //  #{p[:description]}" }.join("\n  // ")

            request_methods_sigs << "#{method_name}(#{method_args})"

            request_methods << %{
  // #{endpoint}
  // #{op[:summary]}
  // #{method_args_doc}
  public function #{method_name}(#{method_args}) \{
    return $this->request('#{op[:method]}', '#{api[:path]}', [ #{method_args_map} ]);
  \}}

            # Generate one mock function and one test function per sample response
            op[:response_messages].each do |r|

              status = r[:code]
              status == :ok if status == :success
              status = Rack::Utils.status_code(status)
              example = r[:responseModel]

              mock_method = "mock_#{path}_returns_#{r[:message].parameterize.gsub('-', '_')}"
              test_method = "test_#{path}_returns_#{r[:message].parameterize.gsub('-', '_')}"
              mock_args = example[:query].nil? ? "''" : example[:query].collect{ |k, v| v.nil? ? "''" : "#{v.inspect}" }.join(', ')
              token = example[:headers].nil? ? '' : example[:headers][CONFIG['authorization_header'] || 'X-Token']

              mock_methods_sigs << "#{mock_method}()"

              # Call the actual method with the sample request to get the sample response
              app = ActionDispatch::Integration::Session.new(Rails.application)
              response = app.send(op[:method], '/' + api[:path], example[:query], example[:headers])
              json = app.body.chomp
              response = nil
              begin
                response = JSON.parse(json)
              rescue
              end

              mock_methods << %{
  public static function #{mock_method}() \{
    $c = new #{client_name_camel}(['token_value' => '#{token}', 'client' => self::createMockClient(
      #{r[:code]}, json_decode(#{json.inspect}, true)
    )]);
    return $c->#{method_name}(#{mock_args});
  \}}
              test_assertions = response.nil? ? '' : recursive_assert(response, '$res')
              test_methods << %{
  public function #{test_method}() \{
    $res = #{client_name_camel}::#{mock_method}();
    #{test_assertions}
  \}}
            end
          end
        end
      end

      # Client class
      client = %{<?php
namespace #{vendor_name_camel}\\#{client_name_camel};

class #{client_name_camel} extends \\Meedan\\Lapis\\LapisClient \{

  function __construct($config = []) \{
    $config['token_name'] = '#{CONFIG['authorization_header'] || 'X-Token'}';
    parent::__construct($config);
  \}
  #{request_methods}
  #{mock_methods}
\}}
      f = File.open(File.join(srcdir, "#{client_name_camel}.php"), 'w')
      f.puts(client)
      f.close

      # phpunit.xml
      phpunit = %{<?xml version="1.0" encoding="UTF-8"?>
  <phpunit bootstrap="vendor/autoload.php" colors="true">
      <testsuites>
          <testsuite name="#{client_name_camel} Test Suite">
              <directory suffix=".php">tests/</directory>
          </testsuite>
      </testsuites>
  </phpunit>}
      f = File.open(File.join(basedir, 'phpunit.xml'), 'w')
      f.puts(phpunit)
      f.close

      # Client test class
      tests = %{<?php
namespace #{vendor_name_camel}\\#{client_name_camel};

class #{client_name_camel}Test extends \\PHPUnit_Framework_TestCase \{
#{test_methods}
\}}
      f = File.open(File.join(testdir, "#{client_name_camel}Test.php"), 'w')
      f.puts(tests)
      f.close

      # README.md
      readme = %{
# #{client_name_camel}

This package is a PHP client for #{api_name_snake}, which defines itself as '#{INFO[:description]}'. It also provides mock methods to test it.

## Installation

Add this line to your application's `composer.json` `require` dependencies:

```php
"#{vendor_name_dash}/#{client_name_dash}": "*"
```

And then execute:

    $ composer install

## Usage

With this package you can call methods from #{api_name_snake}'s API and also test them by using the provided mocks.

The available methods are:

#{request_methods_sigs.collect{ |r| "* #{client_name_camel}::#{r}" }.join("\n")}

If you are going to test something that uses the '#{api_name_snake}' service, first you need to mock each possible response it can return, which are:

#{mock_methods_sigs.collect{ |r| "* #{client_name_camel}::#{r}" }.join("\n")}
      }
      f = File.open(File.join(basedir, 'README.md'), 'w')
      f.puts(readme)
      f.close

      # Finish
      puts
      puts '----------------------------------------------------------------------------------------------------------------'
      puts "Done! Your PHP package is at '#{basedir}'."
      puts '----------------------------------------------------------------------------------------------------------------'
    end
  end
end
