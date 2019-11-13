CONFIG['storage']['public_endpoint'] ||= CONFIG['storage']['endpoint']

credentials = {
  provider:              'AWS',
  aws_access_key_id:     CONFIG['storage']['access_key'],
  aws_secret_access_key: CONFIG['storage']['secret_key'],
  region:                CONFIG['storage']['bucket_region'],
  host:                  URI(CONFIG['storage']['endpoint']).host,
  endpoint:              CONFIG['storage']['endpoint'],
  path_style:            CONFIG['storage']['path_style'] || true
}

bucket_name = CONFIG['storage']['bucket']

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_credentials = credentials
  config.fog_directory  = bucket_name
  config.fog_public = true
  config.storage = :fog
end

connection = Fog::Storage.new(credentials)
bucket = connection.directories.get(bucket_name)

if bucket.nil?
  begin
    connection.directories.create(key: bucket_name, public: true)
    policy = {
      'Version' => '2012-10-17',
      'Statement' => [
        {
          'Effect' => 'Allow',
          'Principal' => {
            'AWS' => ['*']
          },
          'Action' => ['s3:GetObject'],
          'Resource' => ["arn:aws:s3:::#{bucket_name}/*"]
        }
      ]
    }
    bucket = connection.directories.get(bucket_name)
    bucket.service.put_bucket_policy(bucket_name, policy)
  rescue Excon::Error::Conflict
    puts 'Bucket already exists'
  end
end
