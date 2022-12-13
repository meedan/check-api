require_relative '../error_codes'

namespace :lapis do
  task :error_codes do
    LapisConstants::ErrorCodes.all.each do |name|
      puts "#{name}: #{LapisConstants::ErrorCodes.const_get(name)}"
    end
  end
end
