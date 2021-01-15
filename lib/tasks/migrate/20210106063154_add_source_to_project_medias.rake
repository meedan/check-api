namespace :check do
  namespace :migrate do
    task add_source_to_project_medias: :environment do
      Team.find_each do |t|
        ProjectMedia.where(team_id: t).join(:medias).where('medias.type = ?', 'Link')
        .find_in_batches(batch_size: 2500) do |pms|
          
        end
      end
    end
  end
end
