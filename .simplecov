require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console,
])

SimpleCov.start 'rails' do
  nocov_token 'nocov'
  merge_timeout 3600
  command_name "Tests #{rand(100000)}"
  add_filter do |file|
    (!file.filename.match(/\/app\/controllers\/[^\/]+\.rb$/).nil? && file.filename.match(/application_controller\.rb$/).nil?) ||
    !file.filename.match(/\/app\/controllers\/concerns\/[^\/]+_doc\.rb$/).nil? ||
    !file.filename.match(/\/lib\/sample_data\.rb$/).nil? ||
    !file.filename.match(/\/lib\/middleware_sidekiq_server_retry\.rb$/).nil?
  end
  coverage_dir 'coverage'
end
