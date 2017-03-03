# Check Settings Module
# Add to the model: include CheckSettings
# It must have a "settings" column already
# Settings have key and value
# How to get a setting value: object.setting(key)
# How to set a setting value: object.set_key = value

module CheckSettings
  def self.included(base)
    base.class_eval do
      serialize :settings
    end
  end

  def setting(key)
    self.settings = {} if self.settings.blank?
    value = self.settings[key.to_s] || self.settings[key.to_sym]
    unless value.nil?
      value.is_a?(Numeric) ? value.to_s : value
    end
  end

  def method_missing(method, *args, &block)
    match = /^(set|get)_([^=]+)=?$/.match(method)
    if match.nil?
      super
    elsif match[1] === 'set'
      self.settings = {} if self.settings.blank?
      self.settings[match[2].to_sym] = args.first
    elsif match[1] === 'get'
      self.setting(match[2])
    end
  end
end
