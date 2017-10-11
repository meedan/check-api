namespace :test do
  task :coverage do
    require 'simplecov'
    SimpleCov.start 'rails' do
      nocov_token 'nocov'
      add_filter do |file|
        (!file.filename.match(/\/app\/controllers\/[^\/]+\.rb$/).nil? && file.filename.match(/application_controller\.rb$/).nil?) ||
        !file.filename.match(/\/app\/controllers\/concerns\/[^\/]+_doc\.rb$/).nil? ||
        !file.filename.match(/\/lib\/sample_data\.rb$/).nil?
      end
      coverage_dir 'public/coverage'
    end
    Rake::Task['test'].execute
  end
end
