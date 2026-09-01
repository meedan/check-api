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

  # This is useful for local development... external services (like WhatsApp, for example) need to be able to access some local URLs
  def self.rewrite_url(url)
    CheckConfig.get('storage_rewrite_host').blank? ? url : url.gsub(/^https?:\/\/[^\/]+/, CheckConfig.get('storage_rewrite_host'))
  end

  def self.get(path)
    client = Aws::S3::Client.new
    begin
      client.get_object(bucket: CheckConfig.get('storage_bucket'), key: path)
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end
  end

  def self.write(path, content_type, content, bucket=nil, acl = 'public-read')
    bucket ||= CheckConfig.get('storage_bucket')
    client = Aws::S3::Client.new
    object = {
      key: path,
      body: content,
      bucket: bucket,
      content_type: content_type
    }
    object[:acl] = acl unless acl.nil?
    client.put_object(object)
    begin client.put_object_acl(acl: acl, key: path, bucket: bucket) rescue nil end unless acl.nil?
  end

  def self.delete(*paths)
    objects = []
    paths.each do |path|
      objects << { key: path }
    end
    client = Aws::S3::Client.new
    client.delete_objects(bucket: CheckConfig.get('storage_bucket'), delete: { objects: objects })
  end

  def self.write_presigned(path, content_type, content, expires_in, bucket=nil, acl = 'public-read')
    bucket ||= CheckConfig.get('storage_bucket')
    self.write(path, content_type, content, bucket, acl)
    client = Aws::S3::Client.new
    s3 = Aws::S3::Resource.new(client: client)
    obj = s3.bucket(bucket).object(path)
    obj.presigned_url(:get, expires_in: expires_in)
  end
end
