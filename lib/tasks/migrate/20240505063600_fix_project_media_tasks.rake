namespace :check do
  namespace :migrate do
    # Fix ProjectMedias tasks (tasks order and missing tasks)
    # All teams: bundle exec rails check:migrate:fix_project_media_tasks
    # Specific team: bundle exec rails check:migrate:fix_project_media_tasks['team_slug1,team_slug2,...']
    task fix_project_media_tasks: :environment do |_t, args|
      started = Time.now.to_i
      slugs = args.extras
      condition = {}
      if slugs.blank?
        last_team_id = Rails.cache.read('check:migrate:fix_project_media_tasks:team_id') || 0
      else
        last_team_id = 0
        condition = { slug: slugs }
      end
      Team.where(condition).where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.team_tasks.find_each do |tt|
          # Fix task order
          Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia')
          .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', tt.id).find_in_batches(batch_size: 2000) do |tasks|
            task_items = []
            tasks.each do |task|
              print '.'
              data = task.data
              if data['order'] != tt.order
                data['order'] = tt.order
                task.data = data
                task_items << task.attributes
              end
            end
            Task.upsert_all(task_items) unless task_items.blank?
          end
          # Add missing tasks to unconfirmed items
          team.project_medias.where({ archived: [CheckArchivedFlags::FlagCodes::UNCONFIRMED] })
          .joins("LEFT JOIN annotations a ON a.annotation_type = 'task' AND a.annotated_type = 'ProjectMedia'
            AND a.annotated_id = project_medias.id
            AND task_team_task_id(a.annotation_type, a.data) = #{tt.id}")
          .where("a.id" => nil).order(id: :desc).distinct.find_in_batches(batch_size: 2000) do |pms|
            new_tasks = []
            pms.each do |pm|
              print '.'
              data = {
                label: tt.label,
                type: tt.task_type,
                description: tt.description,
                team_task_id: tt.id,
                json_schema: tt.json_schema,
                order: tt.order,
                fieldset: tt.fieldset,
                slug: team.slug,
              }
              data[:options] = tt.options unless tt.options.blank?
              new_tasks << {
                annotation_type: 'task',
                annotated_id: pm.id,
                annotated_type: 'ProjectMedia',
                data: data
              }.with_indifferent_access
            end
            Task.insert_all(new_tasks) unless new_tasks.blank?
          end
        end
        Rails.cache.write('check:migrate:fix_project_media_tasks:team_id', team.id) if slugs.blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
