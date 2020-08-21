require 'aws-sdk-s3'
require 'csv'
require_relative './pg_export'
require_relative './workbench_upload'

# Given {team_slug, workflow_id, step_id, api_token}, export that
# team's data to a tempfile and upload that tempfile to Workbench.
def upload_one(team_slug:, **workbench_params)
  Tempfile.open("#{team_slug}-sqlite3-lz4") do |f|
    f.close
    PgExport::export_team_to_sqlite_lz4_file(team_slug, f.path)
    WorkbenchUpload::upload_file_to_workbench(
      **workbench_params,
      path: f.path,
      filename: "#{team_slug}-#{Date.today.iso8601}.sqlite3.lz4"
    )
  end
end

# Load rows from S3 as {team_slug, workflow_id, step_id, api_token}
#
# The CSV should look like:
#
#     team_slug,workflow_id,step_id,api_token
#     my-team,1412,step-234fDdf,my-api-token
#     ...
def load_rows_from_s3_csv(bucket, key)
  s3 = AWS::S3.new
  csv_bytes = s3.buckets[bucket].objects[key].read
  CSV.parse(csv_bytes, headers: true)
    .map do |row|
      team_slug, workflow_id, step_id, api_token = row.fields(*%w(team_slug workflow_id step_id api_token))
      if team_slug.nil? || workflow_id.nil? || step_id.nil? || api_token.nil?
        puts "Skipping row because values are missing. Contents: #{row.to_s}"
        nil
      else
        {
          team_slug: team_slug,
          workflow_id: workflow_id,
          step_id: step_id,
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
      s3_bucket = ENV["WORKBENCH_INTEGRATION_S3_BUCKET"]
      s3_key = ENV["WORKBENCH_INTEGRATION_S3_KEY"]
      raise "Must set WORKBENCH_INTEGRATION_S3_BUCKET environment variable" if s3_bucket.nil?
      raise "Must set WORKBENCH_INTEGRATION_S3_KEY environment variable" if s3_key.nil?

      load_rows_from_s3_csv(s3_bucket, s3_key).each do |values|
        upload_one(**values)
      end
    end
  end
end
