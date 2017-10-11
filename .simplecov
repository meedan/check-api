SimpleCov.start 'rails' do
  nocov_token 'nocov'
  merge_timeout 3600
  command_name "Tests #{rand(100000)}"
  add_filter do |file|
    (!file.filename.match(/\/app\/controllers\/[^\/]+\.rb$/).nil? && file.filename.match(/application_controller\.rb$/).nil?) ||
    !file.filename.match(/\/app\/controllers\/concerns\/[^\/]+_doc\.rb$/).nil? ||
    !file.filename.match(/\/lib\/sample_data\.rb$/).nil?
  end
  coverage_dir 'public/coverage'
end
