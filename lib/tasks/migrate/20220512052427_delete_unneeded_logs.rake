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
        # - TeamBotInstallation (create/update)
        condition[:item_type] = 'TeamBotInstallation'
        Version.from_partition(team.id).where(condition).delete_all
        # - TiplineSubscription (create/update)
        condition[:item_type] = 'TiplineSubscription'
        Version.from_partition(team.id).where(condition).delete_all
        # - Annotations (create/update/destroy) [keep the following types -['tag', 'report_design', 'verification_status']-]
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