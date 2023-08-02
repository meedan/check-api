namespace :check do
  namespace :migrate do
    task remove_item_add_from_slack_notification: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:remove_item_add_from_slack_notification:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        print '.'
        slack_notifications = team.get_slack_notifications
        unless slack_notifications.nil?
          count = slack_notifications.size
          slack_notifications.delete_if{ |raw| raw['event_type'] == 'item_added' }
          # Check if there is an `item_added` events were deleted
          if slack_notifications.size != count
            team.set_slack_notifications = slack_notifications
            team.save!
          end
        end
        Rails.cache.write('check:migrate:remove_item_add_from_slack_notification:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end