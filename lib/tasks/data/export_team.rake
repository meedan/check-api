require_relative './pg_export'

namespace :check do
  namespace :data do
    desc "Export workspace data to files"
    task :export_team, [:team_slug] => :environment do |task, args|
      # Get team id from passed option
      raise "Usage: #{task.to_s}[team_slug]" unless args.team_slug
      path = "check-#{args.team_slug}.sqlite3.lz4"
      PgExport::export_team_to_sqlite_lz4_file(args.team_slug, path)
      puts "Done! Upload #{path} to a Workbench 'Check' step."
      puts "Run `lz4 --rm -d #{path} to decompress (for debugging)."
    end
  end
end
