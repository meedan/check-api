class ElasticSearchWorker

  include Sidekiq::Worker

  def perform(model, options, type)
    model = YAML::load(model)
    options = set_options(model, options)
    case type
    when "update_team"
      model.update_elasticsearch_team_bg
    when "update_parent"
      model.update_media_search_bg(options)
    when "add_parent"
      model.add_media_search_bg(options)
    when "destroy"
      model.destroy_elasticsearch_data(options)
    else
      model.add_update_media_search_child_bg(type, options)
    end
  end

  private

  def set_options(model, options)
    options = YAML::load(options)
    options[:keys] = [] unless options.has_key?(:keys)
    options[:data] = {} unless options.has_key?(:data)
    options[:parent] = model.get_parent_id unless options.has_key?(:parent)
    options
  end
end
