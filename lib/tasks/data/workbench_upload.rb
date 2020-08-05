require 'aws-sdk-s3'
require 'typhoeus'

module WorkbenchUpload
  def self.upload_file_to_workbench(workflow_id:, step_id:, api_token:, path:, filename:)
    s3_config = get_s3_config_from_workbench(workflow_id, step_id, api_token)
    puts "Uploading to s3://#{s3_config['bucket']}/#{s3_config['key']}"
    upload_file_to_s3(path, s3_config)
    finish_workbench_upload(s3_config['finishUrl'], api_token, filename)
  end

  protected

  def self.raise_on_http_problem(response)
    if not response.success?
      if response.timed_out?
        raise 'HTTP request timed out'
      elsif response.code == 0
        raise "HTTP request did not complete: #{response.return_message}"
      else
        puts response.inspect
        raise "HTTP #{response.status_message}"
      end
    end
  end

  def self.get_s3_config_from_workbench(workflow_id, step_id, api_token)
    url = "https://app.workbenchdata.com/api/v1/workflows/#{workflow_id}/steps/#{step_id}/uploads"
    response = Typhoeus.post(url, headers: {Authorization: "Bearer #{api_token}"})
    raise_on_http_problem(response)
    JSON.parse(response.response_body)
  end

  def self.upload_file_to_s3(path, s3_config)
    s3_client = Aws::S3::Client.new(
      # Commented out: aws-sdk v3 format
      # endpoint: s3_config['endpoint'],
      # force_path_style: true,
      # credentials: Aws::Credentials(
      #   s3_config['credentials']['accessKeyId'],
      #   s3_config['credentials']['secretAccessKey'],
      #   s3_config['credentials']['sessionToken'],
      # )
      # aws-sdk v1 format:
      endpoint: s3_config['endpoint'],
      force_path_style: true,
      access_key_id: s3_config['credentials']['accessKeyId'],
      secret_access_key: s3_config['credentials']['secretAccessKey'],
      session_token: s3_config['credentials']['sessionToken'],
    )
    s3_resource = Aws::S3::Resource.new(client: s3_client)
    s3_resource.bucket(s3_config['bucket']).object(s3_config['key']).upload_file(path)
  end

  def self.finish_workbench_upload(finish_url, api_token, filename)
    response = Typhoeus.post(
      finish_url,
      body: JSON.dump({'filename': filename}),
      headers: {
        Authorization: "Bearer #{api_token}",
        'Content-Type': 'application/json'
      }
    )
    raise_on_http_problem(response)
    response
  end
end
