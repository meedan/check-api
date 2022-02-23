namespace :check do
  namespace :fetch do
    # bundle exec rails check:fetch:clear['team_slug', 'list-of-services']
    task :clear, [:slug, :services] => :environment do |_t, args|
      slug = args[:slug]
      services = args[:services].split('-')
      if slug.blank?
        puts "You should pass workspace slugs to the rake task[check:fetch:clear['team_slug1']"
        exit
      end
      Team.where(slug: slug).find_each do |team|
        puts "Processing #{team.name} workspace..."
        # Steps for clear task
        # 1. Disable fetch bot
        # 2. Destroy imported items
        # 3. Destroy imported items cache (semaphores) and fields named `external_id`
        # 4. Re-install fetch bot
        # 5. Print fetch & app status to build status_mapping
        # Step 1
        fetch_user = BotUser.find_by_login('fetch')
        unless fetch_user.nil?
          tbi = TeamBotInstallation.where(user_id: fetch_user.id, team_id: team.id).last
          tbi.destroy! unless tbi.nil?
        end
        # Step 2
        count = team.project_medias.where(channel: CheckChannels::ChannelCodes::FETCH).joins(:media).where('medias.type' => 'Blank').count
        puts "Step 2: destroying imported reports [#{count}] items "
        team.project_medias.where(channel: CheckChannels::ChannelCodes::FETCH).joins(:media)
        .where('medias.type' => 'Blank').find_each do |pm|
          print '.'
          pm.destroy!
        end
        # Step 3
        Rails.cache.delete_matched("fetch:claim_review_imported:#{team.id}:*")
        DynamicAnnotation::Field.joins("
          INNER JOIN annotations ON annotations.id = dynamic_annotation_fields.annotation_id
          INNER JOIN project_medias ON project_medias.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'
        ")
        .where(
          'project_medias.team_id' => team.id,
          'field_name' => 'external_id',
          'annotations.annotation_type' => 'verification_status'
        ).find_each{ |f| f.destroy! }
        # Step 4
        tbi = TeamBotInstallation.new
        tbi.user = fetch_user
        tbi.team = team
        tbi.save!
        # Step 5
        # Print list of imported status values from Fetch side
        puts "Fetch status..."
        services.each do |service|
          Bot::Fetch.supported_services.select{ |s| s['service'] == service }.last
          params = { service: service, start_time: '1900-01-01', end_time: '2100-01-01', per_page: 10000 }
          Bot::Fetch.call_fetch_api(:get, 'claim_reviews', params)
          .collect{ |cr| cr.dig('reviewRating', 'alternateName') || cr.dig('reviewRating', 'ratingValue').to_s || '' }
          .sort.uniq.reject{ |s| s.blank? }.each{ |s| puts "\"#{s}\" => \"\"," } ; nil
        end
        # Print list of Check statuses
        puts "Check statuses..."
        team.media_verification_statuses['statuses'].each{ |s| puts "#{s['id']}: #{s['label']}" } unless team.media_verification_statuses.nil?
      end
    end

    # bundle exec rails check:fetch:import['team_slug', 'list-of-services']
    task :import, [:slug, :services] => :environment do |_t, args|
      # This task depend on status_mapping
      # TODO: find a good way to pass status mapping to the rake task
      slug = args[:slug]
      services = args[:services].split('-')
      team = Team.find_by_slug(slug)
      unless team.nil?
        # Install fetch
        fetch_user = BotUser.find_by_login('fetch')
        tbi_fetch = TeamBotInstallation.where(user_id: fetch_user.id, team_id: team.id).last
        if tbi_fetch.nil?
          tbi = TeamBotInstallation.new
          tbi.user = fetch_user
          tbi.team = team
          tbi.save!
        end
        Bot::Fetch.set_service(slug, services, "undetermined", status_mapping)
        services.each { |service| Bot::Fetch.call_fetch_api(:delete, 'subscribe', { service: service, url: Bot::Fetch.webhook_url(team) }) }
        services.each { |service| Bot::Fetch.call_fetch_api(:post, 'subscribe', { service: service, url: Bot::Fetch.webhook_url(team) }) }
        Bot::Fetch::Import.delay(retry: 0).import_claim_reviews(TeamBotInstallation.where(user_id: BotUser.find_by_login('fetch').id, team_id: team.id).last.id)
      end
    end
  end
end
