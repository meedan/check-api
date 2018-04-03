class ElasticSearchWorker

  include Sidekiq::Worker
  require 'sidekiq-limit_fetch'
  sidekiq_options queue: 'esqueue', :retry => false

  def perform(model, options, type)
    model = YAML::load(model)
    options = YAML::load(options)
    options[:keys] = [] unless options.has_key?(:keys)
    options[:data] = {} unless options.has_key?(:data)
    options[:parent] = model.get_parent_id unless options.has_key?(:parent)

    if type == 'update_team'
      model.update_elasticsearch_team_bg
    elsif type == 'update_parent'
      model.update_media_search_bg(options)
    elsif type == 'destroy'
      model.destroy_elasticsearch_data(options)
    else
      model.add_update_media_search_child_bg(type, options)
    end
  end

end
