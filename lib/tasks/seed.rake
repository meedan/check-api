namespace :db do
  namespace :seed do
    # Create random data (actually this is an alias for `rake db:seed`
    task :random do
      Rake::Task['db:seed'].invoke
    end
  end
end
