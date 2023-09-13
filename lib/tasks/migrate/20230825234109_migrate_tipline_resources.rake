namespace :check do
  namespace :migrate do
    desc 'Migrate tipline resources: Set language and content type.'
    task tipline_resources: :environment do
      ActiveRecord::Base.logger = nil
      start = Time.now.to_i
      i = 0
      skipped = 0
      migrated = 0
      n = TiplineResource.where(language: nil, content_type: nil).count
      TiplineResource.where(language: nil, content_type: nil).order('id DESC').find_each do |resource|
        i += 1
        begin

          # Set content type
          if resource.rss_feed_url.blank?
            resource.content_type = 'static'
          else
            resource.content_type = 'rss'
          end

          # Set language
          language = nil
          tbi = TeamBotInstallation.where(team: resource.team, user: BotUser.smooch_user).last
          unless tbi.nil?
            tbi.get_smooch_workflows.to_a.each do |workflow|
              workflow['smooch_custom_resources'].to_a.each do |r|
                if r['smooch_custom_resource_id'] == resource.uuid
                  language = workflow['smooch_workflow_language']
                end
              end
            end
          end
          resource.language = language

          # Save
          resource.save!

          migrated += 1
          puts "[#{Time.now}] [#{i}/#{n}] Migrated tipline resource with ID #{resource.id} to content type #{resource.content_type} and language #{resource.language}."
        rescue
          skipped += 1
          puts "[#{Time.now}] [#{i}/#{n}] Skipped tipline resource with ID #{resource.id}."
        end
      end
      finish = Time.now.to_i
      puts "Done in #{finish - start} seconds. Migrated: #{migrated}. Skipped: #{skipped}."
    end
  end
end
