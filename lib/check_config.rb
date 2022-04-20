# Check Config
# Read and process CONFIG

class CheckConfig
  def self.get(key, default = nil, type = nil)
    value = ENV[key]
    value ||= CONFIG[key] if CONFIG.has_key?(key)
    return default if value.nil?
    value = self.parse_value(value) if type == :json
    value = value.to_i if type == :integer
    value = value.to_f if type == :float
    return value unless value.is_a?(Hash) && value.has_key?('lang')
    self.get_lang_value(value)
  end

  def self.parse_value(config)
    begin
      JSON.parse(config.to_s)
    rescue JSON::ParserError
      config
    end
  end

  def self.set(key, value)
    CONFIG[key] = value
  end

  def self.get_lang_value(value)
    return value['lang']['en'] if Team.current.nil? || !Team.current.get_language || !value['lang'].has_key?(Team.current.get_language)
    value['lang'][Team.current.get_language]
  end
end
