class CheckCldr
  LANGUAGE_FORMAT_REGEXP = /^[a-z]{2,3}([_-][a-zA-Z0-9]{2,4})?$/

  def self.load
    data = {}
    Dir.foreach(File.join(Rails.root, 'data')) do |file|
      if File.directory?(File.join(Rails.root, 'data', file))
        yaml = File.join(Rails.root, 'data', file, 'languages.yml')
        data[file] = YAML.load(File.read(yaml))[file]['languages'] if File.exist?(yaml)
      end
    end
    data
  end

  def self.language_code_to_name(code, locale = I18n.locale)
    code = code.to_s.gsub('_', '-')
    short_code = code.to_s.gsub(/[_-].*$/, '')
    short_locale = locale.to_s.gsub(/[_-].*$/, '')
    locale ||= :en
    name = CLDR_LANGUAGES.dig(locale, code) || CLDR_LANGUAGES.dig(short_locale, code) || CLDR_LANGUAGES.dig('en', short_code)
    name.blank? ? code : name.mb_chars.capitalize
  end

  def self.localized_languages(locale = I18n.locale)
    locale ||= :en
    data = {}
    CLDR_LANGUAGES[locale.to_s].each do |code, name|
      data[code] = name.mb_chars.capitalize
    end
    data
  end
end
