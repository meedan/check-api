namespace :lapis do
  task :docs do
    puts %x(cd doc && make && cd -)
    puts 'Check the documentation under doc/:'
    puts '- Licenses'
    puts '- API endpoints'
    puts '- Models and controllers diagrams'
    puts '- Swagger UI'
  end
end
