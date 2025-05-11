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

    def cached_field_expiration(options)
      options[:expires_in] || CheckConfig.get('cache_interval', 30).to_i.days
    end

    def cached_field(name, options = {})
      options = options.with_indifferent_access
      @@cached_fields ||= []
      @@cached_fields << name

      if options[:start_as]
        klass = self
        self.send :after_create, ->(obj) do
          klass.create_cached_field(options, name, obj)
        end
      end

      define_method name do |recalculate = false|
        Rails.cache.fetch(self.class.check_cache_key(self.class, self.id, name), force: recalculate, race_condition_ttl: 30.seconds, expires_in: self.class.cached_field_expiration(options)) do
          if self.respond_to?(options[:recalculate])
            value = self.send(options[:recalculate])
            self.class.index_cached_field(options, value, name, self)
            value
          end
        end
      end

      [options[:update_on]].flatten.each do |update_on|
        model = update_on[:model]
        klass = self
        update_on[:events].each do |event, callback|
          model.send "after_#{event}", ->(obj) do
            klass.update_cached_field(name, obj, update_on[:if], update_on[:affected_ids], callback, options, event)
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

    def index_and_pg_cached_field(options, value, name, target)
      if should_update_cached_field?(options, target)
        update_index = options[:update_es] || false
        value = target.send(update_index, value) if update_index.is_a?(Symbol) && target.respond_to?(update_index)
        field_name = options[:es_field_name].nil? ? [name] : [options[:es_field_name]]&.flatten
        data = {}
        field_name.each{ |f| data[f] = value }
        es_options = { keys: field_name, data: data }
        es_options[:pm_id] = target.id if target.class.name == 'ProjectMedia'
        model = { klass: target.class.name, id: target.id }
        ElasticSearchWorker.new.perform(YAML::dump(model), YAML::dump(es_options), 'update_doc')
      end
      update_pg = options[:update_pg] || false
      update_pg_cache_field(options, value, name, target) if update_pg
    end

    def should_update_cached_field?(options, target)
      update = false
      update_index = options[:update_es] || false
      if update_index && !target.disable_es_callbacks && !RequestStore.store[:disable_es_callbacks]
        # Make sure doc exists in ES as we did document update
        doc_id = target.get_es_doc_id
        update = target.doc_exists?(doc_id) unless doc_id.blank?
      end
      update
    end

    def index_cached_field(options, value, name, obj)
      if options[:update_es] || options[:update_pg]
        index_options = {
          update_es: options[:update_es],
          es_field_name: options[:es_field_name],
          update_pg: options[:update_pg],
          pg_field_name: options[:pg_field_name],
        }
        self.delay_for(1.second, { queue: 'esqueue' }).index_cached_field_bg(index_options, value, name, obj.class.name, obj.id)
      end
    end

    def index_cached_field_bg(index_options, value, name, klass, id)
      obj = klass.constantize.find_by_id id
      self.index_and_pg_cached_field(index_options, value, name, obj) unless obj.nil?
    end

    def update_pg_cache_field(options, value, name, target)
      table_name = target.class.name.tableize
      if ApplicationRecord.connection.data_source_exists?(table_name)
        column_name = options[:pg_field_name] || name
        target.update_column(column_name, value) if ApplicationRecord.connection.column_exists?(table_name, column_name)
      end
    end

    def create_cached_field(options, name, obj)
      return if self.skip_cached_field_update?
      value = options[:start_as].is_a?(Proc) ? options[:start_as].call(obj) : options[:start_as]
      Rails.cache.write(self.check_cache_key(self, obj.id, name), value, expires_in: self.cached_field_expiration(options))
      self.index_cached_field(options, value, name, obj) unless Rails.env == 'test'
    end

    def update_cached_field(name, obj, condition, ids, callback, options, event)
      return if self.skip_cached_field_update?
      condition ||= proc { true }
      return unless condition.call(obj)
      ids = ids.call(obj)
      unless ids.blank?
        # clear cached fields in foreground
        [ids].flatten.each { |id| Rails.cache.delete(self.check_cache_key(self, id, name)) }
        # update cached field in background
        index_options = {
          update_es: options[:update_es],
          es_field_name: options[:es_field_name],
          update_pg: options[:update_pg],
          pg_field_name: options[:pg_field_name],
          recalculate: options[:recalculate],
        }
        self.delay_for(1.second, { queue: 'esqueue' }).update_cached_field_bg(name, ids, callback, index_options, obj.class.name, obj.id, event)
      end
    end

    def update_cached_field_bg(name, ids, callback, options, klass, id, event)
      obj = event == 'destroy' ? klass.constantize : klass.constantize.find_by_id(id)
      unless obj.nil?
        recalculate = options[:recalculate]
        self.where(id: ids).each do |target|
          value = callback == :recalculate ? target.send(recalculate) : obj.send(callback, target)
          Rails.cache.write(self.check_cache_key(self, target.id, name), value, expires_in: self.cached_field_expiration(options))
          # Update ES index and PG, if needed
          self.index_and_pg_cached_field(options, value, name, target)
        end
      end
    end
  end
end
