namespace :check do
  namespace :fetch do
    def parse_args(args)
      data = {}
      return data if args.blank?
      args.each do |a|
        arg = a.split('&')
        arg.each do |pair|
          key, value = pair.split(':')
          data.merge!({ key => value })
        end
      end
      data
    end

    def print_status_mapping(services, team)
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

    # bundle exec rails check:fetch:print_status_mapping['slug:team_slug&services:list|of|services']
    task print_status_mapping: :environment do |_t, args|
      data = parse_args args.extras
      slug = data['slug']
      services = data['services'].split('|')
      print_status_mapping(services, Team.where(slug: slug).first)
    end

    # bundle exec rails check:fetch:clear['slug:team_slug&services:list|of|services']
    task clear: :environment do |_t, args|
      data = parse_args args.extras
      slug = data['slug']
      services = data['services'].split('|')
      if slug.blank? || services.blank?
        puts "You should pass workspace slug and services to the rake task[check:fetch:clear['slug:team_slug&services:list|of|services']"
        exit
      end
      Team.where(slug: slug).find_each do |team|
        puts "Processing #{team.name} workspace..."
        # Steps for clear task
        # 1. Disable Fetch bot
        # 2. Destroy imported items
        # 3. Destroy imported items cache (semaphores) and fields named `external_id`
        # 4. Re-install Fetch bot
        # 5. Print Fetch & Check statuses to build STATUS_MAPPING
        # Step 1
        fetch_user = BotUser.find_by_login('fetch')
        unless fetch_user.nil?
          tbi = TeamBotInstallation.where(user_id: fetch_user.id, team_id: team.id).last
          tbi.destroy! unless tbi.nil?
        end
        # Step 2
        count = team.project_medias.where("channel->>'main' = ?", CheckChannels::ChannelCodes::FETCH.to_s).joins(:media).where('medias.type' => 'Blank').count
        if count > 0
          puts "Step 2: destroying imported reports [#{count}] items "
          RequestStore.store[:disable_es_callbacks] = true
          client = $repository.client
          options = { index: CheckElasticSearchModel.get_index_alias }
          team.project_medias
          .where("channel->>'main' = ?", CheckChannels::ChannelCodes::FETCH.to_s)
          .joins(:media)
          .where('medias.type' => 'Blank')
          .find_in_batches(:batch_size => 1000) do |pms|
            print '.'
            deleted_ids = pms.map(&:id)
            query = { terms: { annotated_id: deleted_ids } }
            options[:body] = { query: query }
            client.delete_by_query options
            pms.each do |pm|
              print '.'
              pm.destroy!
            end
          end
          RequestStore.store[:disable_es_callbacks] = false
        end
        # Step 3
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
        print_status_mapping(services, team)
      end
    end

    # bundle exec rails check:fetch:import['slug:team_slug&services:list|of|services&force=1']
    task import: :environment do |_t, args|
      # This task depends on STATUS_MAPPING environment variable, something like `export STATUS_MAPPING=mapping.to_json`
      # The mapping is a hash, where the key is a Fetch status/rating and the value is an existing Check status identifier (not the label)
      data = parse_args args.extras
      slug = data['slug']
      services = data['services'].split('|')
      force = data['force'].to_i # When "1", ignores existing imported articles and re-import them (e.g., it bypasses cache)
      team = Team.find_by_slug(slug)
      if slug.blank? || services.blank?
        puts "You should pass workspace slug and services to the rake task[check:fetch:import['slug:team_slug&services:list|of|services']"
        exit
      end
      unless team.nil?
        # Get status mapping
        # You must set the status mapping as an environment variable in JSON format (e.g., `export STATUS_MAPPING=mapping.to_json`)
        # The mapping is a hash, where the key is a Fetch status/rating and the value is an existing Check status identifier (not the label)
        begin
          status_mapping = JSON.parse(ENV["STATUS_MAPPING"])
        rescue JSON::ParserError,TypeError
          raise "Couldn't parse a status mapping. Please pass in a JSON status mapping into the STATUS_MAPPING environment variable."
        end
        # Install Fetch bot
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
        tbi = TeamBotInstallation.where(user_id: BotUser.find_by_login('fetch').id, team_id: team.id).last.id
        Bot::Fetch::Import.delay(retry: 0).import_claim_reviews(tbi, force)
      end
    end
  end
end
