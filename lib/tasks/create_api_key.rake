namespace :lapis do
  namespace :api_keys do
    task delete_expired: :environment do
      puts "There are #{ApiKey.count} keys. Going to remove the expired ones..."
      ApiKey.destroy_all('expire_at < ?', Time.now)
      puts "Done! Now there are #{ApiKey.count} keys."
    end

    task create: :environment do
      app = ENV['application']
      api_key = ApiKey.create! application: app
      puts "Created a new API key for #{app} with access token #{api_key.access_token} and that expires at #{api_key.expire_at}"
    end

    task create_dev: :environment do
      app = ENV['application']
      key_name = case ENV['RAILS_ENV']
        when 'test' then 'test'
        when 'development' then 'dev'
      end
      ApiKey.where(access_token: key_name).destroy_all
      api_key = ApiKey.create!
      api_key.access_token = key_name
      api_key.expire_at = api_key.expire_at.since(100.years)
      api_key.save!
      puts "Created a new API key for #{app} with access token #{api_key.access_token} and that expires at #{api_key.expire_at}"
    end
  end
end
