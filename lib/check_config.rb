# Check Config
# Read and process CONFIG

class CheckConfig
  def self.get(key)
    # No setting: return nil
    return nil if !CONFIG.has_key?(key)
    value = CONFIG[key]
    # Not language hash: return verbatim value
    return value if !value.is_a?(Hash) || !value.has_key?('lang')
    # No team context or no team language or team language has no config: return English value
    return value['lang']['en'] if Team.current.nil? || !Team.current.get_language || !value['lang'].has_key?(Team.current.get_language)
    # We can safely return the team's language setting
    value['lang'][Team.current.get_language]
  end
end
