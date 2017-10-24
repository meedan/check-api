unless CONFIG['optics_api_key'].blank?
  optics_agent = OpticsAgent::Agent.new
  optics_agent.configure do 
    schema RelayOnRailsSchema
    api_key CONFIG['optics_api_key']
  end
  Rails.application.config.middleware.use optics_agent.rack_middleware
end
