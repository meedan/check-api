CheckConfig.set('storage_asset_host', "#{CheckConfig.get('storage_endpoint')}/#{CheckConfig.get('storage_bucket')}") if !CheckConfig.get('storage_asset_host')

bucket_name = CheckConfig.get('storage_bucket')

unless bucket_name.blank?
  credentials = {
    provider:              'AWS',
    aws_access_key_id:     CheckConfig.get('storage_access_key'),
    aws_secret_access_key: CheckConfig.get('storage_secret_key'),
    region:                CheckConfig.get('storage_bucket_region'),
    path_style:            CheckConfig.get('storage_path_style').nil? ? true : CheckConfig.get('storage_path_style'),
    endpoint:              CheckConfig.get('storage_endpoint'),
    host:                  CheckConfig.get('storage_endpoint') ? URI(CheckConfig.get('storage_endpoint')).host : ''
  }

  CarrierWave.configure do |config|
    config.fog_provider = 'fog/aws'
    config.fog_credentials = credentials
    config.fog_directory  = bucket_name
    config.fog_public = true
    config.storage = :fog
    config.asset_host = CheckConfig.get('storage_asset_host')
  end

  begin
    connection = Fog::Storage.new(credentials)
    bucket = connection.directories.get(bucket_name)
    if bucket.nil?
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
    end
  rescue Excon::Error::Socket
    puts '[CarrierWave] Failure to connect to storage'
  rescue Excon::Error::Conflict
    puts '[CarrierWave] Bucket already exists'
  end
end
