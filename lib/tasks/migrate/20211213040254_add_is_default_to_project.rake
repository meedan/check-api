namespace :check do
  namespace :migrate do
    task create_workspaces_default_folder: :environment do
      RequestStore.store[:skip_notifications] = true
      started = Time.now.to_i
      errors = []
      team_default_projects = {}
      Project.where(is_default: true).find_each do |p|
        team_default_projects[p.team_id] = p.id
      end
      # Bulk-create default folders for existing workspace
      Team.find_in_batches(:batch_size => 2500) do |teams|
        inserts = []
        teams.each do |t|
          if team_default_projects[t.id].blank?
            inserts << Project.new({
              team_id: t.id,
              title: 'Unnamed folder (default)',
              skip_check_ability: true,
              is_default: true,
            })
          end
        end
        result = Project.import inserts, validate: false, recursive: false, timestamps: true
        # Append new default projects to team_default_projects
        Project.where(id: result.ids.map(&:to_i)).find_each do |np|
          team_default_projects[np.team_id] = np.id
        end
      end
      last_team_id = Rails.cache.read('check:migrate:create_workspaces_default_folder:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        default_folder_id = team_default_projects[team.id]
        if default_folder_id.blank?
          errors << { team: team.slug, id: team.id }
          next
        end
        team.project_medias.where('project_id IS NULL').find_in_batches(:batch_size => 2500) do |pms|
          ids = pms.map(&:id)
          updates = { action: 'move_to', params: { move_to: default_folder_id }.to_json }
          ProjectMedia.bulk_update(ids, updates, team)
        end
        # log last team id
        puts "[#{Time.now}] Done for team #{team.slug}"
        Rails.cache.write('check:migrate:create_workspaces_default_folder:team_id', team.id)
      end
      RequestStore.store[:skip_notifications] = false
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
      puts "Failed to handle the following workspaces #{errors.inspect}" unless errors.blank?
    end
  end
end