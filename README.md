## Checkdesk

[![Code Climate](https://codeclimate.com/repos/5755cb94c1237437b20013c6/badges/b6cd49bb313851a22f23/gpa.svg)](https://codeclimate.com/repos/5755cb94c1237437b20013c6/feed)
[![Issue Count](https://codeclimate.com/repos/5755cb94c1237437b20013c6/badges/b6cd49bb313851a22f23/issue_count.svg)](https://codeclimate.com/repos/5755cb94c1237437b20013c6/feed)
[![Test Coverage](https://codeclimate.com/repos/5755cb94c1237437b20013c6/badges/b6cd49bb313851a22f23/coverage.svg)](https://codeclimate.com/repos/5755cb94c1237437b20013c6/coverage)

Verify breaking news online

### Installation

#### Non-Docker-based

* Configure `config/config.yml`, `config/database.yml`, `config/initializers/errbit.rb` and `config/initializers/secret_token.rb` (check the example files)
* Run `bundle install`
* Run `bundle exec rake db:migrate`
* Create an API key: `bundle exec rake lapis:api_keys:create`
* Start the server: `rails s`
* Go to [http://localhost:3000/api](http://localhost:3000/api) and use the API key you created

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
* `lapis:graphql:update_schema_json`: Update the GraphQL schema JSON
* `swagger:docs:markdown`: Generate the documentation in markdown format

### GraphQL

There is a GraphQL interface that exposes the data model as a GraphQL schema. The GraphQL files should be under `app/graph`.

You can update the schema file by running `rake lapis:graphql:update_schema_json`.

### Migration

Migrate CD2 data

* Add `allow_duplicated_urls: true` to `config.yml`
* Run `drush eval "_checkdesk_core_export_data_csv();"` in `CD2` instance : This command will output a directory inside `[files directory]/checkdesk_migration`.
* Copy the output from the above step `[files directory]/checkdesk_migration/[instance_name]` into CD3 `db/data`.
* Run `rake db:seed:sample`.

### Credits

Meedan (hello@meedan.com)
