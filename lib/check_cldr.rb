class CheckCldr
  def self.load
    data = {}
    Dir.foreach(File.join(Rails.root, 'data')) do |file|
      if file =~ /^[a-z]{2}$/
        yaml = File.join(Rails.root, 'data', file, 'languages.yml')
        data[file] = YAML.load(File.read(yaml))[file]['languages'] if File.exist?(yaml)
      end
    end
    data
  end

  def self.language_code_to_name(code, locale = I18n.locale)
    locale ||= :en
    name = CLDR_LANGUAGES[locale.to_s][code.to_s]
    name.blank? ? code.to_s : name.mb_chars.capitalize
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
