namespace :lapis do
  task :error_codes do
    LapisConstants::ErrorCodes::ALL.each do |name|
      puts name + ': ' + LapisConstants::ErrorCodes.const_get(name).to_s
    end
  end
end
