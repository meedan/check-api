class ElasticSearchWorker
  #include CheckElasticSearchModel
  include Sidekiq::Worker

  def perform(model, options)
    model = YAML::load(model)
    options = YAML::load(options)
    model.save!(options)
  end

end
