# :nocov:
require 'typhoeus'

N_RETRIES = 3

module WorkbenchUpload
  def self.upload_file_to_workbench(step_files_url:, api_token:, path:, filename:)
    attempt = 0
    begin
      tus_upload_url = get_tus_upload_url_from_workbench(
        step_files_url: step_files_url,
        api_token: api_token,
        filename: filename,
        size: File.size(path)
      )
      tus_upload(path, tus_upload_url)
    rescue Typhoeus::Errors::TyphoeusError
      attempt += 1
      if attempt < N_RETRIES
        retry
      else
        raise
      end
    end
  end

  protected

  def self.raise_on_http_problem(response)
    if not response.success?
      if response.timed_out?
        raise Typhoeus::Errors::TyphoeusError, 'HTTP request timed out'
      elsif response.code == 0
        raise Typhoeus::Errors::TyphoeusError, "HTTP request did not complete: #{response.return_message}"
      else
        raise Typhoeus::Errors::TyphoeusError, "HTTP #{response.status_message}: #{response.inspect}"
      end
    end
  end

  def self.get_tus_upload_url_from_workbench(step_files_url:, api_token:, filename:, size:)
    puts "POST #{step_files_url}"
    response = Typhoeus.post(
      step_files_url,
      headers: {
        Authorization: "Bearer #{api_token}",
        "Content-Type": "application/json"
      },
      body: JSON.dump({ filename: filename, size: size })
    )
    raise_on_http_problem(response)
    JSON.parse(response.response_body)['tusUploadUrl']
  end

  def self.tus_upload(path, url)
    puts "PATCH #{url} (contents: #{path})"
    response = Typhoeus.patch(
      url,
      headers: {
        "Content-Type": "application/offset+octet-stream",
        "Tus-Resumable": "1.0.0",
        "Upload-Offset": "0"
      },
      body: File.open(path, "rb").read
    )
    raise_on_http_problem(response)
  end
end
# :nocov:
