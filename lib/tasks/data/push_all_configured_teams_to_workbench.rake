require 'aws-sdk-s3'
require 'csv'
require_relative './pg_export'
require_relative './workbench_upload'

# Given {team_slug, workbench_step_url, api_token}, export that
# team's data to a tempfile and upload that tempfile to Workbench.
def upload_one(team_slug:, workbench_step_url:, api_token:)
  Tempfile.open("#{team_slug}-sqlite3-lz4") do |f|
    f.close
    PgExport::export_team_to_sqlite_lz4_file(team_slug, f.path)
    WorkbenchUpload::upload_file_to_workbench(
      step_files_url: workbench_step_url,
      api_token: api_token,
      path: f.path,
      filename: "#{team_slug}-#{Date.today.iso8601}.sqlite3.lz4"
    )
  end
end

# Load rows from S3 as {team_slug, workbench_step_url, api_token}
#
# The CSV should look like:
#
#     team_slug,workbench_step_url,api_token
#     my-team,1412,step-234fDdf,my-api-token
#     ...
def load_rows_from_s3_csv(bucket, key)
  s3 = Aws::S3::Resource.new
  csv_io = s3.bucket(bucket).object(key).get.body
  CSV.parse(csv_io, headers: true)
    .map do |row|
      team_slug, workbench_step_url, api_token = row.fields(*%w(team_slug workbench_step_url api_token))
      if team_slug.nil? || workbench_step_url.nil? || api_token.nil?
        puts "Skipping row because values are missing. Contents: #{row.to_s}"
        nil
      else
        {
          team_slug: team_slug,
          workbench_step_url: workbench_step_url,
          api_token: api_token,
        }
      end
    end
    .reject(&:nil?)
end

namespace :check do
  namespace :data do
    desc "Upload teams' data to Workbench, as specified in a CSV on S3"
    task :push_all_configured_teams_to_workbench => :environment do |task|
      # To test:
      #
      #     aws s3 mb s3://my-test-bucket
      #     aws s3 cp file.csv s3://my-test-bucket/workbench-upload-urls.csv
      #     docker-compose up -d postgres
      #     docker-compose run --rm --no-deps \
      #         -e WORKBENCH_INTEGRATION_S3_BUCKET=my-test-bucket \
      #         -e WORKBENCH_INTEGRATION_S3_KEY=workbench-upload-urls.csv \
      #         -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
      #         -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
      #         -e AWS_REGION=us-east-1 \
      #         -e storage_bucket_region=us-east-1 \
      #         -e storage_access_key="$AWS_ACCESS_KEY_ID" \
      #         -e storage_secret_key="$AWS_SECRET_ACCESS_KEY" \
      #         -e storage_endpoint="https://s3.us-east-1.amazonaws.com" \
      #         api bundle exec rake check:data:push_all_configured_teams_to_workbench

      s3_bucket = ENV["WORKBENCH_INTEGRATION_S3_BUCKET"]
      s3_key = ENV["WORKBENCH_INTEGRATION_S3_KEY"]
      raise "Must set WORKBENCH_INTEGRATION_S3_BUCKET environment variable" if s3_bucket.nil?
      raise "Must set WORKBENCH_INTEGRATION_S3_KEY environment variable" if s3_key.nil?

      load_rows_from_s3_csv(s3_bucket, s3_key).each do |values|
        begin
          upload_one(**values)
        rescue => err
          puts "Skipping upload of #{values[:team_slug]} because of an error:"
          puts err.message
          puts err.backtrace
        end
      end
    end
  end
end
