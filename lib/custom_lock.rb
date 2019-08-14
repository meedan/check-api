module CustomLock
  def self.included(base)
    base.extend ClassMethods
  end

  def locking_enabled?
    attribute_names = self.changed
    self.class.locking_enabled? && attribute_names.any?{ |att| self.class.includes_optimistic_locking?(att) } && self.class.should_do_optimistic_locking?(self)
  end

  module ClassMethods
    def custom_optimistic_locking(options = {})
      @custom_optimistic_locking_options ||= options
    end

    def includes_optimistic_locking?(attribute)
      @custom_optimistic_locking_options[:include_attributes] ? @custom_optimistic_locking_options[:include_attributes].include?(attribute.to_sym) : true
    end

    def should_do_optimistic_locking?(obj)
      @custom_optimistic_locking_options[:if] ? @custom_optimistic_locking_options[:if].call(obj) : true
    end
  end
end
