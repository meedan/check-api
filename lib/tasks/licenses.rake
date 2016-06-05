namespace :lapis do
  task :licenses do
    Gem.licenses.each do |license, gems| 
      gems.sort_by { |gem| gem.name }.each do |gem|
        puts "Ruby Gem: #{gem.name},#{gem.summary.gsub(',', '')},#{license},#{gem.homepage}"
      end
    end
  end
end
