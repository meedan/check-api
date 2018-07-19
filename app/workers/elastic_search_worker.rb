class ElasticSearchWorker

  include Sidekiq::Worker
  sidekiq_options :queue => :esqueue, :retry => false

  def perform(model, options, type)
    model = YAML::load(model)
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
      model.send(ops[type], options) if model.respond_to?(ops[type])
    end
  end

  private

  def set_options(model, options)
    options = YAML::load(options)
    options[:keys] = [] unless options.has_key?(:keys)
    options[:data] = {} unless options.has_key?(:data)
    options[:obj] = model.get_es_doc_obj unless options.has_key?(:obj)
    options[:doc_id] = model.get_es_doc_id(options[:obj]) unless options.has_key?(:doc_id)
    options
  end
end
