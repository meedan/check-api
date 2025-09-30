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
        (self[field.to_sym] || {}).with_indifferent_access
      end

      define_method field.to_s.singularize do |key|
        self.send("#{field}=", {}) if self.send(field).blank?
        value = self.send(field)[key]
        unless value.nil?
          value.is_a?(Numeric) ? value.to_s : value
        end
      end
    end
  end

  def method_missing(method, *args, &block)
    # We generate the field group dynamically first, so we can use named captures in the regex
    field_regex = self.class.check_settings_fields.map { |f| Regexp.escape("_#{f}_") }.join('|')
    field_group = "(?:#{field_regex}|_)"

    regex = /^(?<action>reset|set|get)(?<field>#{field_group})(?<key>[^=]+)=?$/
    match = regex.match(method)

    if match.nil?
      super
    else
      field = match[:field] == '_' ? 'settings' : match[:field].delete_prefix('_').delete_suffix('_')
      value = self.send(field) || {}
      self.get_set_or_reset_setting_value(match, field, value, args)
    end
  end

  def get_set_or_reset_setting_value(match, field, value, args)
    action = match[:action]
    key = match[:key]

    case action
    when 'set'
      value[key] = args.first
      self.send("#{field}=", value)
    when 'get'
      value[key]
    when 'reset'
      value.delete(key) unless value.blank?
      self.send("#{field}=", value)
    end
  end
end
