class ElasticSearchWorker

  include Sidekiq::Worker
  sidekiq_options :queue => :esqueue, :retry => false

  def perform(model, options, type)
    model = YAML::load(model)
    options = set_options(model, options)
    case type
    when "create_doc"
      model.create_elasticsearch_doc_bg
    when "update_doc"
      model.update_elasticsearch_doc_bg(options)
    when "update_doc_team"
      model.update_elasticsearch_doc_team_bg
    when "create_doc_nested"
      model.create_nested_obj_bg(options)
    when "destroy_doc"
      model.destroy_elasticsearch_doc(options)
    when "destroy_doc_nested"
      model.destroy_elasticsearch_doc_nested(options)
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
