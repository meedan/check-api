class CheckI18n
  def self.convert_numbers(str)
    return nil if str.blank?
    # altzeros = [0x0030, 0x0660, 0x06F0, 0x07C0, 0x0966, 0x09E6, 0x0A66, 0x0AE6, 0x0B66, 0x0BE6, 0x0C66, 0x0CE6, 0x0D66, 0x0DE6, 0x0E50, 0x0ED0, 0x0F20, 0x1040, 0x1090, 0x17E0, 0x1810, 0x1946, 0x19D0, 0x1A80, 0x1A90, 0x1B50, 0x1BB0, 0x1C40, 0x1C50, 0xA620, 0xA8D0, 0xA900, 0xA9D0, 0xA9F0, 0xAA50, 0xABF0, 0xFF10]
    # digits = altzeros.flat_map { |z| ((z.chr(Encoding::UTF_8))..((z+9).chr(Encoding::UTF_8))).to_a }.join('')
    # replacements = "0123456789" * altzeros.size
    # str.tr(digits, replacements).to_i
  end

  def self.is_rtl_lang?
    rtl_lang = [
      'ae', 'ar',  'arc','bcc', 'bqi','ckb', 'dv','fa',
      'glk', 'he', 'ku', 'mzn','nqo', 'pnb','ps', 'sd', 'ug','ur','yi'
    ]
    rtl_lang.include?(I18n.locale.to_s) ? true : false
  end

  def self.i18n_t(team, key, fallback, options = {})
    options.merge!({ locale: team.get_language }) if team&.get_language
    options.merge!({ locale: I18n.locale.to_s }) if options[:locale].blank?
    if team && !fallback.blank?
      i18nkey = "custom_message_#{key}_#{team.slug}"
      (options[:locale].to_s != 'en' && I18n.exists?(i18nkey) && !I18n.t(i18nkey.to_sym, options).blank?) ? I18n.t(i18nkey.to_sym, options) : fallback.gsub(/%{[^}]+}/) { |x| options.with_indifferent_access[x.gsub(/[%{}]/, '')] }
    else
      I18n.t(key.to_sym, options)
    end
  end

  def self.upload_custom_strings_to_transifex_in_background(team, prefix, strings)
    if !CheckConfig.get('transifex_user').blank? && !CheckConfig.get('transifex_password').blank?
      self.delay_for(1.second).lock_and_upload_custom_strings_to_transifex(team.id, prefix, strings)
    end
  end

  def self.lock_and_upload_custom_strings_to_transifex(team_id, prefix, strings)
    team = Team.where(id: team_id).last
    return if team.nil?
    key = "transifex:locked:team:#{team.id}"
    raise("Custom Strings Transifex Lock found for team #{team.name}!") if Rails.cache.read(key).to_i == 1
    begin
      Rails.cache.write(key, 1)
      self.upload_custom_strings_to_transifex(team, prefix, strings)
      Rails.cache.write(key, 0)
    rescue StandardError => e
      Rails.cache.write(key, 0)
      raise e
    end
  end

  def self.upload_custom_strings_to_transifex(team, prefix, strings)
    require 'transifex'
    Transifex.configure do |c|
      c.client_login = CheckConfig.get('transifex_user')
      c.client_secret = CheckConfig.get('transifex_password')
    end
    project = Transifex::Project.new(CheckConfig.get('transifex_project'))
    resource_slug = 'api-custom-messages-' + team.slug
    resource = nil
    yaml = { 'en' => {} }

    begin
      resource = project.resource(resource_slug)
      resource.fetch
      yaml = YAML.load(resource.translation('en').fetch['content'])
    rescue Transifex::TransifexError
      resource = nil
    end

    yaml['en'].delete_if { |k, _v| k.to_s =~ /^custom_message_#{prefix}_/ }

    count = 0
    strings.each do |key, value|
      if !value.blank?
        count += 1
        yaml['en']['custom_message_' + prefix + '_' + key + '_' + team.slug] = value
      end
    end

    if count > 0
      if resource.nil?
        Transifex::Resources.new(CheckConfig.get('transifex_project')).create({ slug: resource_slug, name: "Custom Messages: #{team.name}", i18n_type: 'YML', content: yaml.to_yaml })
      else
        resource.content.update(i18n_type: 'YML', content: yaml.to_yaml)
      end
    end
  end
end
