require 'lograge'

Rails.application.configure do
  if Rails.env.test?
    config.lograge.enabled = false
  else
    config.lograge.enabled = true

    config.lograge.logger = ActiveSupport::Logger.new(STDOUT)
    config.lograge.custom_options = lambda do |event|
      options = event.payload.slice(:request_id, :user_id)
      options[:params] = event.payload[:params].except("controller", "action")
      options[:time] = Time.now
      options
    end
    config.lograge.formatter = Lograge::Formatters::Json.new
  end
end
