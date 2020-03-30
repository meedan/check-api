unless CONFIG['airbrake']['host'].blank?
  Airbrake.configure do |config|
    config.project_key = CONFIG['airbrake']['project_key']
    config.project_id = 1
    config.host = "https://#{CONFIG['airbrake']['host']}:#{CONFIG['airbrake']['port']}"
    config.ignore_environments = %w(development test)
    config.environment = CONFIG['airbrake']['environment']
  end
end
