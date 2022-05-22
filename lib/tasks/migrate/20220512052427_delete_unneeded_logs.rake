namespace :check do
  namespace :migrate do
    task delete_unneeded_logs: :environment do
      started = Time.now.to_i
      data = [] 
      last_team_id = Rails.cache.read('check:migrate:delete_unneeded_logs:team_id') || 0
      # Team.where('id > ?', last_team_id).find_each do |team|
      Team.where(slug: 'rappler').find_each do |team|
        puts "Process team : #{team.slug}"
        before_c = Version.from_partition(team.id).count
        condition = {}
        # - Account  (create/update)
        condition[:item_type] = 'Account'
        Version.from_partition(team.id).where(condition).delete_all
        # - BotResource (create/update)
        condition[:item_type] = 'BotResource'
        Version.from_partition(team.id).where(condition).delete_all
        # - Team (create/update)
        condition[:item_type] = 'Team'
        Version.from_partition(team.id).where(condition).delete_all
        # - Media (create/update)
        condition[:item_type] = 'Media'
        Version.from_partition(team.id).where(condition).delete_all
        # - Project (create/update)
        condition[:item_type] = 'Project'
        Version.from_partition(team.id).where(condition).delete_all
        # - Source (create/update)
        condition[:item_type] = 'Source'
        Version.from_partition(team.id).where(condition).delete_all
        # -Comment
        condition[:item_type] = 'Comment'
        Version.from_partition(team.id).where(condition).delete_all
        # TODO: Review tags logs
        # - TiplineSubscription (create/update)
        condition[:item_type] = 'TiplineSubscription'
        Version.from_partition(team.id).where(condition).where.not(event: 'destroy').delete_all
        # - Annotations (create/update/destroy) [keep the following types -['report_design', 'verification_status']-]
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          pm_ids = pm.map(&:id)
          Dynamic.where(annotated_type: 'ProjectMedia', annotated_id: pm_ids)
          .where.not(annotation_type: ['verification_status', 'report_design']).find_in_batches(:batch_size => 2500) do |ds|
            ds_ids = ds.map(&:id)
            Version.from_partition(team.id).where(item_type: 'Dynamic', item_id: ds_ids).delete_all
          end
        end
        # - TODO
        # - Field (create/update) [keep the following field names -[verification_status_status] || , f.annotation_type =~ /^task_response/]-]
        after_c = Version.from_partition(team.id).count
        diff_c = before_c - after_c
        data << { team: team.slug, count: diff_c }
        Rails.cache.write('check:migrate:delete_unneeded_logs:team_id', team.id)
      end
      pp data
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end