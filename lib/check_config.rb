# Check Config
# Read and process CONFIG

class CheckConfig
  def self.get(key, default = nil, type = nil)
    value = ENV[key]
    value ||= CONFIG[key] if CONFIG.has_key?(key)
    # No setting: return default
    return default if value.nil?
    value = self.parse_value(value) if type == :json
    # Not language hash: return verbatim value
    return value unless value.is_a?(Hash) && value.has_key?('lang')
    # No team context or no team language or team language has no config: return English value
    return value['lang']['en'] if Team.current.nil? || !Team.current.get_language || !value['lang'].has_key?(Team.current.get_language)
    # We can safely return the team's language setting
    value['lang'][Team.current.get_language]
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

end
