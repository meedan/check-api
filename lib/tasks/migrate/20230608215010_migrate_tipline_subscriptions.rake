namespace :check do
  namespace :migrate do
    desc 'Migrate tipline subscriptions from Smooch to CAPI'
    task :tipline_subscriptions, [:slug, :phone] => :environment do |_task, args|
      if args[:slug].blank? || args[:phone].blank?
        puts 'Usage: bundle exec rake check:migrate:tipline_subscriptions[workspace-slug,tipline-phone-number-only-digits]'
        exit 1
      end
      ActiveRecord::Base.logger = nil
      tipline_phone = args[:phone].strip
      start = Time.now.to_i
      team = Team.find_by_slug(args[:slug])
      n = TiplineSubscription.where(team: team).count
      i = 0
      errors = 0
      migrated = 0
      TiplineSubscription.where(team: team).find_each do |subscription|
        i += 1
        begin
          old_uid = subscription.uid
          user_data = JSON.parse(DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: old_uid).last.annotation.load.get_field_value('smooch_user_data'))
          user_phone = user_data.dig('raw', 'clients', 0, 'externalId').gsub(/[^0-9]/, '')
          new_uid = "#{tipline_phone}:#{user_phone}"
          subscription.uid = new_uid
          subscription.save!
          puts "[#{Time.now}] [#{i}/#{n}] Migrated subscription with ID #{subscription.id} from UID #{old_uid} to #{new_uid}"
          migrated += 1
        rescue StandardError => e
          puts "[#{Time.now}] [#{i}/#{n}] Could not migrate subscription with ID #{subscription.id}: #{e.message}"
          errors += 1
        end
      end
      finish = Time.now.to_i
      puts "Done in #{finish - start} seconds. Migrated: #{migrated}. Errors: #{errors}"
    end
  end
end
