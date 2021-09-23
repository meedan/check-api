class ElasticSearchWorker

  include Sidekiq::Worker

  sidekiq_options :queue => :esqueue, :retry => 5

  sidekiq_retry_in { |_count, _e| 5 }

  def perform(model, options, type)
    model = begin YAML::load(model) rescue nil end
    unless model.nil?
      options = set_options(model, options)
      ops = {
        'create_doc' => 'create_elasticsearch_doc_bg',
        'update_doc' => 'update_elasticsearch_doc_bg',
        'update_doc_team' => 'update_elasticsearch_doc_team_bg',
        'create_update_doc_nested' => 'create_update_nested_obj_bg',
        'destroy_doc' => 'destroy_elasticsearch_doc',
        'destroy_doc_nested' => 'destroy_elasticsearch_doc_nested',
      }
      unless ops[type].nil?
        model.send(ops[type], options) if should_perform_es_action?(type, options) && model.respond_to?(ops[type])
      end
    end
  end

  private

  def should_perform_es_action?(type, options)
    # Verify that object still exists in PG (should skip destroy operation)
    action = false
    if type == 'destroy_doc' || type == 'update_doc_team'
      action = true
    elsif !options[:doc_id].blank? && options[:obj].class.name == 'ProjectMedia'
      action = ProjectMedia.exists?(options[:obj].id)
    end
    action
  end

  def set_options(model, options)
    options = YAML::load(options)
    options[:keys] = [] unless options.has_key?(:keys)
    options[:data] = {} unless options.has_key?(:data)
    options[:obj] = model.get_es_doc_obj unless options.has_key?(:obj)
    options[:doc_id] = model.get_es_doc_id(options[:obj]) unless options.has_key?(:doc_id)
    options
  end
end
