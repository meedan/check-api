# Check Settings Module
# Add to the model: include CheckdeskSettings
# It must have a "settings" column already
# Settings have key and value
# How to get a setting value: object.setting(key)
# How to set a setting value: object.set_key = value

module CheckdeskSettings
  def self.included(base)
    base.class_eval do
      serialize :settings
    end
  end

  def setting(key)
    self.settings ||= {}
    self.settings[key.to_s] || self.settings[key.to_sym]
  end

  def method_missing(method, *args, &block)
    match = /^set_(.+)=$/.match(method)
    if match.nil?
      super
    else
      key = match[1]
      self.settings ||= {}
      self.settings[key.to_sym] = args.first
    end
  end
end
