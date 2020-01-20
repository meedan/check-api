module CheckCachedFields
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def cached_field(name, options = {})
      options = options.with_indifferent_access

      if options[:start_as]
        self.send :after_create, ->(obj) do
          value = options[:start_as].is_a?(Proc) ? options[:start_as].call(obj) : options[:start_as]
          Rails.cache.write(self.class.check_cache_key(self.class, self.id, name), value)
        end
      end

      define_method name do |recalculate = false|
        Rails.cache.fetch(self.class.check_cache_key(self.class, self.id, name), force: recalculate, race_condition_ttl: 30.seconds) do
          options[:recalculate].call(self)
        end
      end

      [options[:update_on]].flatten.each do |update_on|
        model = update_on[:model]
        klass = self
        update_on[:events].each do |event, callback|
          model.send("after_#{event}", ->(obj) { klass.update_cached_field(name, obj, update_on[:if], update_on[:affected_ids], callback, options) })
        end
      end
    end

    def check_cache_key(klass, id, name)
      "check_cached_field:#{klass}:#{id}:#{name}"
    end

    def update_cached_field(name, obj, condition, ids, callback, options)
      condition ||= proc { true }
      return unless condition.call(obj)
      recalculate = options[:recalculate]
      update_index = options[:update_es] || false
      self.where(id: ids.call(obj)).each do |target|
        value = callback == :recalculate ? recalculate.call(target) : callback.call(target, obj)
        Rails.cache.write("check_cached_field:#{self}:#{target.id}:#{name}", value)
        target.updated_at = Time.now
        target.skip_check_ability = true
        target.save!
        # update es index
        if update_index
          options = { keys: [name], data: { name => value }, parent: target }
          ElasticSearchWorker.perform_in(1.second, YAML::dump(target), YAML::dump(options), 'update_doc')
        end
      end
    end
  end
end
