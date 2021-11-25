namespace :lapis do
  task :docs do
    abort "E: The current environment is `#{Rails.env}`. Please run CheckAPI in `test` mode to generate the documentation" unless Rails.env.test?
    puts %x(cd doc && make clean && make && cd -)
    puts 'Check the documentation under doc/:'
    puts '- Licenses'
    puts '- API endpoints'
    puts '- Models and controllers diagrams'
    puts '- Swagger UI'
  end
end
