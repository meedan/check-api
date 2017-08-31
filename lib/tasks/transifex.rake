require 'transifex'

TRANSIFEX_PROJECT_SLUG = 'check-2'

namespace :transifex do

  # Login on Transifex

  task login: :environment do
    Transifex.configure do |c|
      c.client_login = CONFIG['transifex_user']
      c.client_secret = CONFIG['transifex_password']
    end
    puts "Logged in as #{CONFIG['transifex_user']} on Transifex."
  end

  # Get the supported languages on Transifex and update config/application.rb accordingly

  task languages: [:environment, :login] do
    project = Transifex::Project.new(TRANSIFEX_PROJECT_SLUG)
    @langs = project.languages.fetch.collect{ |l| l['language_code'] } + ['en']
    apprb_path = File.join(Rails.root, 'config', 'application.rb')
    apprb_contents = File.read(apprb_path)
    apprb = File.open(apprb_path, 'w+')
    disclaimer = 'Do not change manually! Use `rake transifex:languages` instead, or set the `locale` key in your `config/config.yml`'
    apprb.puts apprb_contents.gsub(/config\.i18n\.available_locales = \[[^\]]*\] # #{disclaimer}/, "config.i18n.available_locales = #{@langs.to_json} # #{disclaimer}")
    apprb.close
    puts "Set languages #{@langs.join(', ')} on #{apprb_path}."
  end

  # Download translations from Transifex

  task download: [:environment, :languages, :login] do
    project = Transifex::Project.new(TRANSIFEX_PROJECT_SLUG)
    resource = nil

    begin
      resource = project.resource('api')
      @langs.each do |lang|
        next if lang == 'en'
        translation = resource.translation(lang).fetch['content']
        path = File.join(Rails.root, 'config', 'locales', "#{lang}.yml")
        file = File.open(path, 'w+')
        file.puts translation
        file.close
        puts "Downloaded translations from Transifex and saved as #{path}."
      end
    rescue Transifex::TransifexError => e
      if e.message == 'Not Found'
        puts "Tried to download translations, but resource 'API' was not found."
      else
        raise e
      end
    end
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
      resource.content.update(i18n_type: 'YML', content: File.read(File.join(Rails.root, 'config', 'locales', 'en.yml')))
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
