unless CONFIG['honeycomb_key'].blank?
  Honeycomb.configure do |config|
    config.write_key = CONFIG['honeycomb_key']
    config.dataset = CONFIG['honeycomb_dataset']
    config.service_name = 'Check'
  end
end
