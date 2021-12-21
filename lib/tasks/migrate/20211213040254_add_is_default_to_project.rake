namespace :check do
  namespace :migrate do
    task create_workspaces_default_folder: :environment do
      RequestStore.store[:skip_notifications] = true
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:create_workspaces_default_folder:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        default_folder = team.default_folder
        if default_folder.nil?
          default_folder = Project.new
          default_folder.team_id = team.id
          default_folder.title = 'Unnamed folder (default)'
          default_folder.skip_check_ability = true
          default_folder.is_default = true
          default_folder.save!
        end
        team.project_medias.where('project_id IS NULL').find_in_batches(:batch_size => 2500) do |pms|
          ids = pms.map(&:id)
          updates = { action: 'move_to', params: { move_to: default_folder.id }.to_json }
          ProjectMedia.bulk_update(ids, updates, team)
        end
        # log last team id
        puts "[#{Time.now}] Done for team #{team.slug}"
        Rails.cache.write('check:migrate:create_workspaces_default_folder:team_id', team.id)
      end
      RequestStore.store[:skip_notifications] = false
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end