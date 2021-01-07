require 'aws-sdk-s3'

Aws.config.update(
  endpoint: CheckConfig.get('storage_endpoint'),
  access_key_id: CheckConfig.get('storage_access_key'),
  secret_access_key: CheckConfig.get('storage_secret_key'),
  force_path_style: true,
  region: CheckConfig.get('storage_bucket_region')
)

class CheckS3
  def self.resource
    Aws::S3::Resource.new
  end

  def self.bucket
    self.resource.bucket(CheckConfig.get('storage_bucket'))
  end

  def self.exist?(path)
    self.bucket.object(path).exists?
  end

  def self.read(path)
    data = self.get(path)
    return nil unless data
    data.body.read
  end

  def self.public_url(path)
    begin Aws::S3::Object.new(CheckConfig.get('storage_bucket'), path).public_url rescue nil end
  end

  def self.get(path)
    client = Aws::S3::Client.new
    begin
      client.get_object(bucket: CheckConfig.get('storage_bucket'), key: path)
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end
  end

  def self.write(path, content_type, content)
    client = Aws::S3::Client.new
    client.put_object(
      acl: 'public-read',
      key: path,
      body: content,
      bucket: CheckConfig.get('storage_bucket'),
      content_type: content_type
    )
    begin client.put_object_acl(acl: 'public-read', key: path, bucket: CheckConfig.get('storage_bucket')) rescue nil end
  end

  def self.delete(*paths)
    objects = []
    paths.each do |path|
      objects << { key: path }
    end
    client = Aws::S3::Client.new
    client.delete_objects(bucket: CheckConfig.get('storage_bucket'), delete: { objects: objects })
  end
end
