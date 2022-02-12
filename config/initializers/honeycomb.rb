class CustomSampler
  extend Honeycomb::DeterministicSampler

  def self.sample(fields)
    if ['http_request', 'sql.active_record'].include?(fields['name']) && should_sample(1, fields['trace.trace_id'])
      return [true, 8]
    end
    return [false, 0]
  end
end

unless CheckConfig.get('honeycomb_key').blank?
  Honeycomb.configure do |config|
    config.write_key = CheckConfig.get('honeycomb_key')
    config.dataset = CheckConfig.get('honeycomb_dataset')
    config.service_name = 'Check'
    config.sample_hook do |fields|
      CustomSampler.sample(fields)
    end
    config.notification_events = ['sql.active_record', 'request', 'http_request', 'app']
  end
end
