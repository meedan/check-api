class ElasticSearchWorker

  include Sidekiq::Worker
  require 'sidekiq-limit_fetch'
  sidekiq_options queue: 'esqueue', :retry => false

  def perform(model, keys, type)
    model = YAML::load(model)
    keys = YAML::load(keys)

    if type == 'update_parent'
      model.update_media_search_bg(keys)
    else
      model.add_update_media_search_child_bg(type, keys)
    end
  end

end
