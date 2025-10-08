# Check Settings Module
# Add to the model: check_settings :<field>
# It must have a <field> column already
# Settings have key and value
# How to get a setting value: object.get_<field>_key or object.<field>(key)
# How to set a setting value: object.set_<field>_key = value
# How to reset a setting value: object.reset_<field>_key
# If <field> is "settings" (the default), it can be omitted

module CheckSettings
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def check_settings_fields
      @check_settings_fields || []
    end

    def add_check_settings_field(field)
      @check_settings_fields ||= []
      @check_settings_fields << field
    end

    def check_settings(field = :settings)
      serialize field

      self.add_check_settings_field(field)

      define_method field do
        self[field.to_sym] || {}
      end

      define_method field.to_s.singularize do |key|
        self.send("#{field}=", {}) if self.send(field).blank?
        value = self.send(field)[key.to_s] || self.send(field)[key.to_sym]
        unless value.nil?
          value.is_a?(Numeric) ? value.to_s : value
        end
      end
    end
  end

  def method_missing(method, *args, &block)
    regexp = "(#{self.class.check_settings_fields.collect{ |f| "_#{f}_" }.join('|')}|_)"
    match = /^(reset|set|get)#{regexp}([^=]+)=?$/.match(method)
    if match.nil?
      super
    else
      field = match[2] == '_' ? 'settings' : match[2].gsub(/^_|_$/, '')
      value = self.send(field) || {}
      self.get_set_or_reset_setting_value(match, field, value, args)
    end
  end

  def get_set_or_reset_setting_value(match, field, value, args)
    if match[1] === 'set'
      value[match[3].to_sym] = args.first
      self.send("#{field}=", value)
    elsif match[1] === 'get'
      value[match[3].to_sym].nil? ? value[match[3].to_s] : value[match[3].to_sym]
    elsif match[1] === 'reset'
      value.delete(match[3].to_sym) unless value.blank?
      self.send("#{field}=", value)
    end
  end
end
