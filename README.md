## Check

[![Code Climate](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/gpa.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/feed)
[![Test Coverage](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/coverage.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/coverage)
[![Issue Count](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/issue_count.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/feed)
[![Travis](https://travis-ci.org/meedan/check-api.svg?branch=develop)](https://travis-ci.org/meedan/check-api/)

Verify breaking news online

### Installation

#### Non-Docker-based

* Configure `config/config.yml`, `config/database.yml`, `config/initializers/errbit.rb` and `config/initializers/secret_token.rb` (check the example files)
* Run `bundle install`
* Run `bundle exec rake db:migrate`
* Create an API key: `bundle exec rake lapis:api_keys:create`
* Start the server: `rails s`
* Go to [http://localhost:3000/api](http://localhost:3000/api) and use the API key you created

You can optionally use Puma, which allows you to restart the Rails server by doing: `touch tmp/restart.txt`. In order to do that, instead of `rails s`, start the server with `bundle exec pumactl start`.

#### Docker-based

* You can also start the application on Docker by running `rake lapis:docker:run` (it will run on port 3000 and your local hostname) - you first need to create an API key after entering the container (`lapis:docker:shell`) before using the web interface

### Running the tests

* `bundle install --without nothing`
* `RAILS_ENV=test bundle exec rake db:migrate`
* `RAILS_ENV=test bundle exec rake test:coverage`

### Integration

Other applications can communicate with this service (and test this communication) using the client library, which can be automatically generated. Other applications can also use functions exposed by this application in the client library. In order to do this, just add a tag `@expose` before the method definition, like this:

```ruby
  # Other comments come here
  # @expose
  def this_function_will_be_exposed(params)
    # It's important that the exposed function can work standalonely
  end
```

### Rake tasks

There are rake tasks for a few tasks (besides Rails' default ones). Run them this way: `bundle exec rake <task name>`

* `test:coverage`: Run all tests and calculate test coverage
* `application=<application name> lapis:api_keys:create`: Create a new API key for an application
* `lapis:api_keys:delete_expired`: Delete all expired keys
* `lapis:error_codes`: List all error codes that this application can return
* `lapis:licenses`: List the licenses of all libraries used by this project
* `lapis:client:ruby`: Generate a client Ruby gem, that allows other applications to communicate and test this service
* `lapis:client:php`: Generate a client PHP library, that allows other applications to communicate and test this service
* `lapis:docs`: Generate the documentation for this API, including models and controllers diagrams, Swagger, API endpoints, licenses, etc.
* `lapis:docker:run`: Run the application in Docker
* `lapis:docker:shell`: Enter the Docker container
* `lapis:graphql:schema`: Update the GraphQL schema JSON
* `swagger:docs:markdown`: Generate the documentation in markdown format
* `transifex:localize`: Localize the application using Transifex and I18n

### GraphQL

There is a GraphQL interface that exposes the data model as a GraphQL schema. The GraphQL files should be under `app/graph`.

You can update the schema file by running `rake lapis:graphql:schema`.

### Background processing

Some tasks run in background, for example: Slack notifications. They are processed using Sidekiq. Start Sidekiq with `bundle exec sidekiq` and monitor through the web interface at `/sidekiq`. We suggest that you protect that path with HTTP authentication.

### Virus validation for uploaded files

In order to look for viruses on the files uploaded by users, you need to setup the configuration option `clamav_service_path`, which should be something like: `host:port`. A ClamAV service should be running at that address. If that configuration option is not set, uploaded files will skip the safety validation.

You can also test your instance of ClamAV REST this way:

* Set the *test* configuration `clamav_service_path` to point to your instance
* Run this: `bundle exec ruby test/models/uploaded_file_test.rb -n /real/`
* Two tests should pass

The test uses a EICAR file (a test file which is recognized as a virus by scanners even though it's not really a virus).

### Localization

Localization is powered by Transifex + I18n. In order to localize the application, you need to set the `transifex_user` and `transifex_password` configuration options on `config/config.yml`. Then, when you run `rake transifex:localize`, the following will happen automatically:

* The supported languages on Transifex will be set as the available languages for I18n on `config/application.rb`
* New translations will be downloaded from Transifex and saved under `config/locales`
* New localizable strings will be parsed from code, saved on `config/locales/en.yml` and sent to Transifex

We call "localizable strings" any call to the `I18n.t` function like this: `I18n.t(:string_unique_id, default: 'English string')`.

Clients should send the `Accept-Language` header in order to get localized content. If you want to serve everything in English, just add `locale: 'en'` to your `config/config.yml`.

### Credits

Meedan (hello@meedan.com)
