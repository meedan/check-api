unless CheckConfig.get('airbrake_host').blank?
  Airbrake.configure do |config|
    config.project_key = CheckConfig.get('airbrake_project_key')
    config.project_id = 1
    config.host = "https://#{CheckConfig.get('airbrake_host')}:#{CheckConfig.get('airbrake_port')}"
    config.ignore_environments = %w(development test)
    config.environment = CheckConfig.get('airbrake_environment')
  end
end
