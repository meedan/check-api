namespace :watch do

  task :default => [:restart]

  desc "touch tmp/restart.txt any time a file changes on disk in this directory"
  task restart: :environment do
    sh "nodemon --watch app --watch config --watch lib --watch vendor -e rake,rb,yml --exec \"touch\" tmp/restart.txt"
  end
end


task :watch => 'watch:restart'
