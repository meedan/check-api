require 'transifex'

TRANSIFEX_PROJECT_SLUG = 'check-2'

namespace :transifex do

  # Login on Transifex

  task login: :environment do
    Transifex.configure do |c|
      c.client_login = CheckConfig.get('transifex_user')
      c.client_secret = CheckConfig.get('transifex_password')
    end
    puts "Logged in as #{CheckConfig.get('transifex_user')} on Transifex."
  end

  # Get the supported languages from Transifex

  task languages: [:environment, :login] do
    project = Transifex::Project.new(TRANSIFEX_PROJECT_SLUG)
    @langs = project.languages.fetch.collect{ |l| l['language_code'] } + ['en']
    puts "Got languages #{@langs.join(', ')}."
  end

  # Download translations from Transifex - api resource

  task download: [:environment, :languages, :login] do
    project = Transifex::Project.new(TRANSIFEX_PROJECT_SLUG)
    resource_slugs = project.resources.fetch.select{ |r| r['slug'] =~ /^api/ }.collect{ |r| r['slug'] }
    @langs.each do |lang|
      yaml = {}
      yaml[lang] = {}
      resource_slugs.each do |slug|
        resource = project.resource(slug)
        translations = YAML.load(resource.translation(lang).fetch['content'])
        yaml[lang].merge!(translations[lang])
      end
      path = File.join(Rails.root, 'config', 'locales', "#{lang}.yml")
      file = File.open(path, 'w+')
      file.puts yaml.to_yaml
      file.close
      puts "Downloaded translations from Transifex and saved as #{path}."
    end
  end

  # Download translations from Transifex - tipline resource

  task download_tipline: [:environment, :login] do
    project = Transifex::Project.new('check-tiplines')
    langs = project.languages.fetch.collect{ |l| l['language_code'] }
    yaml = {}
    langs.each do |lang|
      yaml[lang] = {}
      resource = project.resource('hardcoded-bot-strings')
      translations = YAML.load(resource.translation(lang).fetch['content'])
      yaml[lang].merge!(translations)
    end
    path = File.join(Rails.root, 'config', "tipline_strings.yml")
    file = File.open(path, 'w+')
    file.puts yaml.to_yaml
    file.close
    puts "Downloaded translations from Transifex and saved as #{path}."
  end

  # Parse code for I18n.t() calls and update the strings on config/locales/en.yml

  task parse: [:environment] do
    path = File.join(Rails.root, 'config', 'locales', 'en.yml')
    yaml = YAML.load(File.read(path))
    Dir.glob('{app,lib}/**/*.rb').each do |filename|
      next if File.directory?(filename)
      file = File.open(filename, 'r')
      file.readlines.each do |line|
        line.scan(/I18n\.t[( ][':"]([a-z\-_0-9]+)['"]?, default: ['"]([^'"]+)['"]/).each { |id, default| yaml['en'][id] = default }
      end
    end

    file = File.open(path, 'w+')
    file.puts yaml.to_yaml
    file.close

    puts "Updated #{path} with localizable strings found on code."
  end

  # Update or create the resource on Transifex

  task upload: [:environment, :login] do
    project = Transifex::Project.new(TRANSIFEX_PROJECT_SLUG)
    resource = nil

    begin
      resource = project.resource('api')
      resource.fetch
      yaml = { 'en' => {} }
      YAML.load(File.read(File.join(Rails.root, 'config', 'locales', 'en.yml')))['en'].each do |key, value|
        yaml['en'][key] = value unless key =~ /^custom_message_/
      end
      resource.content.update(i18n_type: 'YML', content: yaml.to_yaml)
    rescue Transifex::TransifexError => e
      if e.message == 'Not Found'
        params = { slug: 'api', name: 'API', i18n_type: 'YML', content: File.read(File.join(Rails.root, 'config', 'locales', 'en.yml')) }
        options = { trad_from_file: true }
        project.resources.create(params, options)
        resource = project.resource('api')
      else
        raise e
      end
    end

    puts "Uploaded strings to Transifex."
  end

  task localize: [:environment, :login, :languages, :download, :parse, :upload] do
    puts "Localizing the application using Transifex."
  end
end
