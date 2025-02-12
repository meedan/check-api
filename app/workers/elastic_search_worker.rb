class ElasticSearchWorker

  include Sidekiq::Worker

  sidekiq_options :queue => :esqueue, :retry => 3

  sidekiq_retry_in { |_count, _e| 3 }

  def perform(model_data, options, type)
    model_data = begin YAML::load(model_data) rescue nil end
    unless model_data.nil?
      model = model_data[:klass].constantize.find_by_id model_data[:id]
      if !model.nil? || ['destroy_doc', 'destroy_doc_nested'].include?(type)
        options = set_options(model, options, type)
        ops = {
          'create_doc' => 'create_elasticsearch_doc_bg',
          'update_doc' => 'update_elasticsearch_doc_bg',
          'update_doc_team' => 'update_elasticsearch_doc_team_bg',
          'create_update_doc_nested' => 'create_update_nested_obj_bg',
          'destroy_doc' => 'destroy_elasticsearch_doc',
          'destroy_doc_nested' => 'destroy_elasticsearch_doc_nested',
        }
        if !ops[type].nil? && should_perform_es_action?(type, options, model, ops[type])
          if type == 'destroy_doc' || type == 'destroy_doc_nested'
            options[:model_id] = model_data[:id]
            model_data[:klass].constantize.send(ops[type],options)
          else
            model.send(ops[type], options)
          end
        end
      end
    end
  end

  private

  def should_perform_es_action?(type, options, model, op)
    # Verify that object still exists in PG (should skip destroy operation)
    action = false
    if ['destroy_doc', 'destroy_doc_nested', 'update_doc_team'].include?(type)
      action = true
    elsif !options[:doc_id].blank? && !options[:pm_id].nil?
      action = ProjectMedia.exists?(options[:pm_id]) && model.respond_to?(op)
    end
    action
  end

  def set_options(model, options, type)
    options = YAML::load(options)
    if ['destroy_doc', 'destroy_doc_nested'].include?(type)
      options[:doc_id] = Base64.encode64("ProjectMedia/#{options[:pm_id]}")
    end
    options[:keys] = [] unless options.has_key?(:keys)
    options[:data] = {} unless options.has_key?(:data)
    options[:skip_get_data] = false unless options.has_key?(:skip_get_data)
    options[:pm_id] = model.get_es_doc_obj unless options.has_key?(:pm_id)
    options[:doc_id] = model.get_es_doc_id(options[:pm_id]) unless options.has_key?(:doc_id)
    options
  end
end
