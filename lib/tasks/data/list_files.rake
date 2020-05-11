namespace :check do
  namespace :data do
    desc "List uploaded files for a given team id or slug"
    task :list_files, [:team] => :environment do |task, args|
      # Get team id from passed option
      raise "Usage: #{task.to_s}[team id or slug]" unless args.team
      team = if args.team.to_i > 0
        Team.find_by_id args.team
      else
        Team.find_by_slug args.team
      end

      # List the image paths.
      pms = ProjectMedia.where(:team_id => team.id).joins(:media).where('medias.type IN (?)', ['UploadedImage', 'UploadedVideo', 'UploadedFile'])
      pms.each { |pm| puts(pm.media.file.file.public_url) }
    end
  end
end
