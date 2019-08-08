require 'aws-sdk-s3'

Aws.config.update(
  endpoint: CONFIG.dig('storage', 'endpoint'),
  access_key_id: CONFIG.dig('storage', 'access_key'),
  secret_access_key: CONFIG.dig('storage', 'secret_key'),
  force_path_style: true,
  region: CONFIG.dig('storage', 'bucket_region')
)

class CheckS3
  def self.resource
    Aws::S3::Resource.new
  end

  def self.bucket
    self.resource.bucket(CONFIG['storage']['bucket'])
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
    begin Aws::S3::Object.new(CONFIG['storage']['bucket'], path).public_url.gsub(/^#{Regexp.escape(CONFIG['storage']['endpoint'])}/, CONFIG['storage']['public_endpoint']) rescue nil end
  end

  def self.get(path)
    client = Aws::S3::Client.new
    begin
      client.get_object(bucket: CONFIG['storage']['bucket'], key: path)
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
      bucket: CONFIG['storage']['bucket'],
      content_type: content_type
    )
    begin client.put_object_acl(acl: 'public-read', key: path, bucket: CONFIG['storage']['bucket']) rescue nil end
  end

  def self.delete(*paths)
    objects = []
    paths.each do |path|
      objects << { key: path }
    end
    client = Aws::S3::Client.new
    client.delete_objects(bucket: CONFIG['storage']['bucket'], delete: { objects: objects })
  end
end
