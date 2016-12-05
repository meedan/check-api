class ElasticSearchWorker
  #include CheckElasticSearchModel
  include Sidekiq::Worker

  def perform(model, options = {})
    model = YAML::load(model)
    model.save!(options)
  end

end
