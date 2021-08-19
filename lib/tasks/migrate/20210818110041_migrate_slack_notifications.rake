namespace :check do
  namespace :migrate do
    task migrate_slack_notifications: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:migrate_slack_notifications:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        print '.'
        slack_notifications = []
        slack_channel = team.settings.with_indifferent_access[:slack_channel]
        i = 0
        slack_notifications << {
          label: "Notifcation ##{i+=1}",
          event_type: "any_activity",
          slack_channel: slack_channel
        } unless slack_channel.blank?
        team.projects.find_in_batches(:batch_size => 2500) do |ps|
          ps.each do |p|
            slack_events = p.settings[:slack_events]
            slack_events.each do |event|
              slack_channel = event.with_indifferent_access[:slack_channel]
              slack_notifications << {
                label: "Notifcation ##{i+=1}",
                event_type: "item_added",
                values: ["#{p.id}"],
                slack_channel: slack_channel
              }
            end unless slack_events.blank?
          end
        end
        team.slack_notifications = slack_notifications.to_json
        team.save!
        Rails.cache.write('check:migrate:migrate_slack_notifications:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end