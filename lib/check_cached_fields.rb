module CheckCachedFields
  def self.included(base)
    base.send :extend, ClassMethods
  end

  def clear_cached_fields
    self.class.cached_fields.each { |name| Rails.cache.delete(self.class.check_cache_key(self.class, self.id, name)) }
  end

  module ClassMethods
    def skip_cached_field_update?
      RequestStore.store[:skip_cached_field_update]
    end

    def cached_fields
      @@cached_fields.to_a.uniq.sort
    end

    def cached_field(name, options = {})
      options = options.with_indifferent_access
      interval = CheckConfig.get('cache_interval', 30).to_i
      @@cached_fields ||= []
      @@cached_fields << name

      if options[:start_as]
        klass = self
        self.send :after_create, ->(obj) do
          return if self.class.skip_cached_field_update?
          value = options[:start_as].is_a?(Proc) ? options[:start_as].call(obj) : options[:start_as]
          Rails.cache.write(self.class.check_cache_key(self.class, self.id, name), value, expires_in: interval.days)
          klass.index_and_pg_cached_field(options, value, name, obj, 'create') unless Rails.env == 'test'
        end
      end

      define_method name do |recalculate = false|
        Rails.cache.fetch(self.class.check_cache_key(self.class, self.id, name),force: recalculate,
          race_condition_ttl: 30.seconds, expires_in: interval.days) do
          options[:recalculate].call(self)
        end
      end

      [options[:update_on]].flatten.each do |update_on|
        model = update_on[:model]
        klass = self
        update_on[:events].each do |event, callback|
          model.send "after_#{event}", ->(obj) do
            return if klass.skip_cached_field_update?
            klass.update_cached_field(name, obj, update_on[:if], update_on[:affected_ids], callback, options)
          end
        end
      end

      # Clear cached field from Redis
      self.send :before_destroy, ->(_obj) do
        Rails.cache.delete(self.class.check_cache_key(self.class, self.id, name))
      end
    end

    def check_cache_key(klass, id, name)
      "check_cached_field:#{klass}:#{id}:#{name}"
    end

    def index_and_pg_cached_field(options, value, name, target, op)
      update_index = options[:update_es] || false
      if update_index && op == 'update'
        value = update_index.call(target, value) if update_index.is_a?(Proc)
        field_name = options[:es_field_name] || name
        es_options = { keys: [field_name], data: { field_name => value } }
        es_options[:pm_id] = target.id if target.class.name == 'ProjectMedia'
        model = { klass: target.class.name, id: target.id }
        ElasticSearchWorker.perform_in(1.second, YAML::dump(model), YAML::dump(es_options), 'update_doc')
      end
      update_pg = options[:update_pg] || false
      update_pg_cache_field(options, value, name, target) if update_pg
    end

    def update_pg_cache_field(options, value, name, target)
      table_name = target.class.name.tableize
      if ApplicationRecord.connection.data_source_exists?(table_name)
        column_name = options[:pg_field_name] || name
        target.update_column(column_name, value) if ApplicationRecord.connection.column_exists?(table_name, column_name)
      end
    end

    def update_cached_field(name, obj, condition, ids, callback, options)
      condition ||= proc { true }
      return unless condition.call(obj)
      recalculate = options[:recalculate]
      interval = CheckConfig.get('cache_interval', 30).to_i
      self.where(id: ids.call(obj)).each do |target|
        value = callback == :recalculate ? recalculate.call(target) : callback.call(target, obj)
        Rails.cache.write(self.check_cache_key(self, target.id, name), value, expires_in: interval.days)
        # Update ES index and PG, if needed
        self.index_and_pg_cached_field(options, value, name, target, 'update')
      end
    end
  end
end
