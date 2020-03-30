unless CONFIG['clamav_service_path'].blank?
  ENV['CLAMD_TCP_HOST'], ENV['CLAMD_TCP_PORT'] = CONFIG['clamav_service_path'].split(':')
end
