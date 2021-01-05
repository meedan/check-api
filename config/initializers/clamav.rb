unless CheckConfig.get('clamav_service_path').blank?
  ENV['CLAMD_TCP_HOST'], ENV['CLAMD_TCP_PORT'] = CheckConfig.get('clamav_service_path').split(':')
end
