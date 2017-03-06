class ElasticSearchWorker

  include Sidekiq::Worker
  require 'sidekiq-limit_fetch'
  sidekiq_options queue: 'esqueue', :retry => false

  def perform(model, keys, data, type)
    model = YAML::load(model)
    keys = YAML::load(keys)
    data = YAML::load(data)

    if type == 'update_team'
      model.update_elasticsearch_team_bg
    elsif type == 'update_parent'
      model.update_media_search_bg(keys, data)
    else
      model.add_update_media_search_child_bg(type, keys, data)
    end
  end

end
