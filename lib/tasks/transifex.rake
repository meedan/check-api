require 'transifex'

TRANSIFEX_CHECKUI_PROJECT_SLUG = 'check-2'
TRANSIFEX_TIPLINES_PROJECT_SLUG = 'check-tiplines'

namespace :transifex do

  # Get the supported languages on Transifex and update config/application.rb accordingly

  task languages: [:environment, :login] do
    project = Transifex::Project.new(TRANSIFEX_CHECKUI_PROJECT_SLUG)
    @langs_ui = project.languages.fetch.collect{ |l| l['language_code'] } + ['en']
    project = Transifex::Project.new(TRANSIFEX_TIPLINES_PROJECT_SLUG)
    @langs_tl = project.languages.fetch.collect{ |l| l['language_code'] }
    langs = (@langs_ui + @langs_tl).uniq
    apprb_path = File.join(Rails.root, 'config', 'application.rb')
    apprb_contents = File.read(apprb_path)
    apprb = File.open(apprb_path, 'w+')
    disclaimer = 'Do not change manually! Use `rake transifex:languages` instead, or set the `locale` key in your `config/config.yml`'
    apprb.puts apprb_contents.gsub(/config\.i18n\.available_locales = \[[^\]]*\] # #{disclaimer}/, "config.i18n.available_locales = #{langs.to_json} # #{disclaimer}")
    apprb.close
    puts "Set languages #{langs.join(', ')} on #{apprb_path}."
  end

  # Download translations from Transifex - tipline resource

  task download_tipline: [:environment, :login] do
    project = Transifex::Project.new(TRANSIFEX_TIPLINES_PROJECT_SLUG)
    @langs_tl = project.languages.fetch.collect{ |l| l['language_code'] }
    yaml = {}
    @langs_tl.each do |lang|
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
end
