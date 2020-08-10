require_relative './pg_export'
require_relative './workbench_upload'

namespace :check do
  namespace :data do
    desc "Upload workspace data to Workbench Check module"
    task :push_team_to_workbench, [:team_slug, :workflow_id, :step_id, :api_token] => :environment do |task, args|
      raise "Usage: #{task.to_s}[team_slug,workflow_id,step_id,api_token]" unless (
        args.team_slug && args.workflow_id && args.step_id && args.api_token
      )

      Tempfile.open("#{args.team_slug}-sqlite3-lz4") do |f|
        f.close
        PgExport::export_team_to_sqlite_lz4_file(args.team_slug, f.path)
        WorkbenchUpload::upload_file_to_workbench(
          workflow_id: args.workflow_id,
          step_id: args.step_id,
          api_token: args.api_token,
          path: f.path,
          filename: "#{args.team_slug}-#{Date.today.iso8601}.sqlite3.lz4"
        )
      end
    end
  end
end
