## Check

[![Code Climate](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/gpa.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/feed)
[![Test Coverage](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/coverage.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/coverage)
[![Issue Count](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/issue_count.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/feed)
[![Travis](https://travis-ci.org/meedan/check-api.svg?branch=develop)](https://travis-ci.org/meedan/check-api/)

Verify breaking news online.

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

### Theming 

#### Themeing the sign in page

The log in page is a separate static page. Edit `app/assets/sass/home.scss` and compile the CSS with node sass. This is not currently supported in the docker container. From outside the container install node-sass: `npm install -g node-sass` then `node-sass --watch ./app/assets/sass/home.scss ./public/css/home.css`

#### Themeing inside the app

All pages except the sign in page use a customized Rails Admin Material UI theme. You can customize it by editing the Sass files in `app/stylesheets/rails_admin/custom/`. The Rails asset pipeline should parse them automatically. 

You can force recompilation with: `rake assets:clean && rake assets:precompile`.

#### Restarting while theming

Changing configuration files requires a restart of the API. 

From inside the container: `touch tmp/restart.txt`.

### Running the tests

* `bundle install --without nothing`
* `RAILS_ENV=test bundle exec rake db:migrate`
* `RAILS_ENV=test bundle exec rake test:coverage`

### Running the tests in parallel

* `bundle install --without nothing`
* `./scripts/setup-parallel-env.sh`
* `RAILS_ENV=test bundle exec rake "parallel:test[3]"` (replace `3` by the number of threads you want)

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

### Integration with Pender archives

* Add a migration that creates a new dynamic annotation for the archiver
* Declare this new type at `app/models/bot/keep.rb`
* Add the readable name of that archiver to `config/locales/en.yml`
* Add the default limit value for that archiver to `lib/check_limits.rb` and `app/views/rails_admin/main/_limits.html.erb` (you may need to add a migration too)

### Implement a new workflow

**IMPORTANT: Your annotation type must match your workflow class name... for example, Workflow::YourStatus for your class name and your_status for the annotation type**

* Add a class `Workflow::YourStatus` to `app/models/workflow/your_status.rb` that inherits from `Workflow::Base`
* Add a migration to create that dynamic annotation type (type should be the same name as the class, e.g., `your_status`)
* Add translations to `config/locales/*.yml`
* Add core values to `config/core_statuses.yml`
* Add the new class to the list `Workflow::Workflow.workflows`
* Take a look at existing implementations under `app/models/workflow/*`

### Localization

Localization is powered by Transifex + I18n. In order to localize the application, you need to set the `transifex_user` and `transifex_password` configuration options on `config/config.yml`. Then, when you run `rake transifex:localize`, the following will happen automatically:

* The supported languages on Transifex will be set as the available languages for I18n on `config/application.rb`
* New translations will be downloaded from Transifex and saved under `config/locales`
* New localizable strings will be parsed from code, saved on `config/locales/en.yml` and sent to Transifex

We call "localizable strings" any call to the `I18n.t` function like this: `I18n.t(:string_unique_id, default: 'English string')`.

Clients should send the `Accept-Language` header in order to get localized content. If you want to serve everything in English, just add `locale: 'en'` to your `config/config.yml`.

#### Update CLDR data

CLDR data lives in `data/` (symlinked as `cldr-data` too) and contains data from CLDR download by `ruby-cldr`. In order to update its contents (as explained [here](https://github.com/svenfuchs/ruby-cldr/issues/24#issuecomment-65855492)), run this in Rails console:

```ruby
require 'cldr/thor'
thor = Cldr::Thor.new
thor.download
thor.export
```

### Admin UI

#### Add new settings fields

* Create a method on model to receive the data and set it to the setting field. For example, in `app/models/team.rb`:

```ruby
  def media_verification_statuses=(statuses)
    self.send(:set_media_verification_statuses, statuses)
  end
```

* Configure the fields on Admin UI (`config/initializers/rails_admin.rb`)

**`show` block**: on config for the model (as example, `Team`) configure the type of field (as example, `json`) and the label to be displayed. Fields that are supposed to be Array or Hash could be configured as `json` be easier to read.

```ruby
show do
  configure :get_media_verification_statuses, :json do
    label 'Media verification statuses'
  end
  (...)
end
```

**`edit` block**: on config for the model (as example, `Team`) configure the type of field (as example, `yaml`), the label to be displayed and the help with a description.
Fields that are supposed to be Array or Hash could be configured as `yaml`, that is more flexible than JSON format.

For `yaml` fields the content should be displayed on a `textarea` and have an example for the field. Just include `render_settings('text')` and add an example in a partial file, like `app/views/rails_admin/main/_media_verification_statuses.html.erb`

```ruby
edit do
  field :media_verification_statuses, :yaml do
    label 'Media verification statuses'
    render_settings('text')
    help "A list of custom verification statuses for reports that match your team's journalistic guidelines."
  end
end
```

For `string` fields the content should be displayed on a `text_field` and have an example for the field. Just include `render_settings('field')` and add an example in a partial file, like `app/views/rails_admin/main/_suggested_tags.html.erb`. Also, the `formatted_value` should be included like `formatted value { bindings[:object].get_suggested_tags }`.

```ruby
edit do
  field :suggested_tags do
    label 'Suggested tags'
    formatted_value { bindings[:object].get_suggested_tags }
    help "A list of common tags to be used with reports and sources in your team."
    render_settings('field')
  end
end
```

### Checkdesk migration

#### Checkdesk side

* Run `drush vset "check_story_ids" --format=json [id1,id2,id3]` to migrate specific stories
* Run `drush eval "_checkdesk_core_export_data_csv();"` : This command will output a directory inside `[files directory]/checkdesk_migration/[[instance-name]]`.
* [instance-name] directory contain the following CSV files
  - `00_teams.csv` : id, team_name, slug, logo
  - `01_users.csv` : name, email, password, profile_image, skip_confirmation_mail, uuid, provider, created_at, login
  - `02_team_users.csv` : team_id, user_id, role, status, created_at, updated_at
  - `03_projects.csv` : id, title, team_id, user_id, description, lead_image, created_at, updated_at
  - `04_project_medias.csv` : id, project_id, url, user_id, created_at, updated_at
  - `05_tags.csv` : annotator_id, annotator_type, annotated_id, annotated_type, tag, created_at, updated_at
  - `06_comments.csv` : annotator_id, annotator_type, annotated_id, annotated_type, comment, created_at, updated_at
  - `07_statuses.csv` : annotator_id, annotator_type, annotated_id, annotated_type, status, created_at, updated_at
  - `08_flags.csv` : annotator_id, annotator_type, annotated_id, annotated_type, flag, created_at, updated_at
* Copy the output from the above step `[instance-name]` into Check `db/data`.

#### Check side

* Run `rake db:migrate:checkdesk`.
* Rake command will generate `mapping_ids.yml` to log Checkdesk => Check mapping and mark migrated model.

### Apollo integration

* Copy `config/apollo-engine-proxy.json.example` to `config/apollo-engine-proxy.json` and add your API key
* Point the clients (e.g., `check-web`) to the proxy host and port

### Credits

Meedan (hello@meedan.com)
