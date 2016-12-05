class ElasticSearchWorker
  include CheckElasticSearchModel
  include Sidekiq::Worker

  def perform(model, keys, options = {})
    keys.each do |k|
      model.send("#{k}=", self.data[k]) if model.respond_to?("#{k}=")
    end
    model.save!(options)
  end

end
