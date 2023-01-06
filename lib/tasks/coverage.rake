namespace :test do
  task :coverage do
    require 'simplecov'
    require 'simplecov-console'
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
    ])
    SimpleCov.start 'rails' do
      nocov_token 'nocov'
      add_filter do |file|
        (!file.filename.match(/\/app\/controllers\/[^\/]+\.rb$/).nil? && file.filename.match(/application_controller\.rb$/).nil?) ||
        !file.filename.match(/\/app\/controllers\/concerns\/[^\/]+_doc\.rb$/).nil? ||
        !file.filename.match(/\/lib\/sample_data\.rb$/).nil? ||
        !file.filename.match(/\/lib\/tasks\//).nil? ||
        !file.filename.match(/\/app\/graph\/types\/mutation_type\.rb$/).nil? ||
        !file.filename.match(/\/app\/graphql\/types\/mutation_type\.rb$/).nil? ||
        !file.filename.match(/\/lib\/check_statistics\.rb$/).nil?
      end
      coverage_dir 'coverage'
    end
    Rake::Task['test'].execute
  end
end
