namespace :test do
  task :coverage do
    require 'simplecov'
    SimpleCov.start 'rails' do
      coverage_dir 'public/coverage'
    end
    Rake::Task['test'].execute
  end
end
