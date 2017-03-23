class ElasticSearchWorker

  include Sidekiq::Worker
  require 'sidekiq-limit_fetch'
  sidekiq_options queue: 'esqueue', :retry => false

  def perform(model, keys, data, parent, type)
    model = YAML::load(model)
    keys = YAML::load(keys)
    data = YAML::load(data)
    parent = model.get_parent_id if parent.nil?

    if type == 'update_team'
      model.update_elasticsearch_team_bg
    elsif type == 'update_parent'
      model.update_media_search_bg(keys, data, parent)
    else
      model.add_update_media_search_child_bg(type, keys, data, parent)
    end
  end

end
