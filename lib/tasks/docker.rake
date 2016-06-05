namespace :lapis do
  namespace :docker do
    task :run do
      exec('./docker/run.sh')
    end

    task :shell do
      exec('./docker/shell.sh')
    end
  end
end
