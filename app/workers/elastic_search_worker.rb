class ElasticSearchWorker

  include Sidekiq::Worker

  sidekiq_options :queue => :esqueue, :retry => 5

  sidekiq_retries_exhausted { |msg, e| Airbrake.notify(e, msg) if Airbrake.configured? && e.is_a?(Elasticsearch::Transport::Transport::Errors::Conflict) }

  sidekiq_retry_in { |_count, _e| 5 }

  def perform(model, options, type)
    model = YAML::load(model)
    options = set_options(model, options)
    if type == 'check_bulk_update'
      MediaSearch.elasticsearch_bulk_update(options)
    else
      ops = {
        'create_doc' => 'create_elasticsearch_doc_bg',
        'update_doc' => 'update_elasticsearch_doc_bg',
        'update_doc_team' => 'update_elasticsearch_doc_team_bg',
        'create_update_doc_nested' => 'create_update_nested_obj_bg',
        'destroy_doc' => 'destroy_elasticsearch_doc',
        'destroy_doc_nested' => 'destroy_elasticsearch_doc_nested',
        'check_bulk_update' => 'elasticsearch_bulk_update'
      }
      unless ops[type].nil?
        model.send(ops[type], options) if model.respond_to?(ops[type])
      end
    end
  end

  private

  def set_options(model, options)
    options = YAML::load(options)
    options[:skip_extra_data] ||= false
    unless options[:skip_extra_data]
      options[:keys] = [] unless options.has_key?(:keys)
      options[:data] = {} unless options.has_key?(:data)
      options[:obj] = model.get_es_doc_obj unless options.has_key?(:obj)
      options[:doc_id] = model.get_es_doc_id(options[:obj]) unless options.has_key?(:doc_id)
    end
    options
  end
end
