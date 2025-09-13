# How to set a service for a Fetch bot installation using Rails console:
# > Bot::Fetch.set_service(team_slug, [service_names], status_fallback, status_mapping ({ reviewRating.(ratingValue|alternameName) => Check status identifier }, as a JSON object))

class Bot::Fetch < BotUser

  class Error < ::StandardError
  end

  # Class extensions

  TeamBotInstallation.class_eval do
    validate :service_is_supported, if: proc { |tbi| tbi.bot_user&.identifier == 'fetch' }

    after_save do
      if self.bot_user.identifier == 'fetch'
        previous_services = ::Bot::Fetch.convert_service_name(self.settings_before_last_save.to_h.with_indifferent_access[:fetch_service_name])
        new_services = ::Bot::Fetch.convert_service_name(self.settings.to_h.with_indifferent_access[:fetch_service_name])
        if new_services != previous_services
          Bot::Fetch.setup_service(self, previous_services, new_services)
        end
      end
    end

    private

    def service_is_supported
      services = ::Bot::Fetch.convert_service_name(self.settings.to_h.with_indifferent_access[:fetch_service_name])
      services.each { |service| errors.add(:base, I18n.t(:fetch_bot_service_unsupported)) if !service.blank? && !Bot::Fetch.is_service_supported?(service) }
    end
  end

  # Mandatory methods that all core bots must have

  check_settings

  def self.convert_service_name(value)
    [value].flatten.reject{ |str| str.blank? }.uniq.sort
  end

  def self.valid_request?(request)
    installation = self.get_installation_for_team(request.query_parameters['team'])
    request.query_parameters['token'] == CheckConfig.get('fetch_token') && !installation.nil?
  end

  def self.webhook(request)
    installation = self.get_installation_for_team(request.query_parameters['team'])
    self.run(request.params['claim_review'], installation)
  end

  def self.run(claim_review, installation)
    begin
      RequestStore.store[:skip_notifications] = true
      User.current = installation.user
      Team.current = installation.team
      status_mapping = installation.get_status_mapping.blank? ? nil : JSON.parse(installation.get_status_mapping, { quirks_mode: true })
      FetchWorker.perform_in(1.second, claim_review, installation.team_id, installation.user_id, installation.get_status_fallback, status_mapping, installation.get_auto_publish_reports)
      true
    rescue StandardError => e
      Rails.logger.error("[Fetch Bot] Exception: #{e.message}")
      CheckSentry.notify(e, bot: 'Fetch', claim_review: claim_review, installation: installation.id)
      false
    end
  end

  # Custom methods start here

  def self.subscriptions(service)
    self.call_fetch_api(:get, 'subscribe', { service: service })
  end

  def self.get_installation_for_team(team_slug)
    bot_id = BotUser.fetch_user&.id
    team_id = Team.where(slug: team_slug).last&.id
    TeamBotInstallation.where(user_id: bot_id, team_id: team_id).last
  end

  def self.set_service(team_slug, service_name, status_fallback, status_mapping)
    installation = self.get_installation_for_team(team_slug)
    installation.set_fetch_service_name([service_name].flatten)
    installation.set_status_fallback(status_fallback)
    installation.set_status_mapping(status_mapping.to_json)
    installation.save!
  end

  def self.webhook_url(team)
    CheckConfig.get('fetch_check_webhook_url') + '/api/webhooks/fetch?team=' + team.slug + '&token=' + CheckConfig.get('fetch_token')
  end

  def self.setup_service(installation, previous_services, new_services, language=nil)
    team = installation.team
    new_services.each do |new_service|
      if self.is_service_supported?(new_service)
        self.call_fetch_api(:post, 'subscribe', { service: new_service, url: self.webhook_url(team), language: language })
      end
    end
    previous_services.each { |previous_service| self.call_fetch_api(:delete, 'subscribe', { service: previous_service, url: self.webhook_url(team) }) }
    Bot::Fetch::Import.delay_for(1.second, { queue: 'fetch', retry: 0 }).import_claim_reviews(installation.id, language, false, nil) unless new_services.blank?
  end

  def self.is_service_supported?(service)
    self.supported_services.collect{ |s| s['service'].to_s }.include?(service.to_s)
  end

  def self.supported_services
    self.call_fetch_api(:get, :services)['services']
  end

  def self.get_claim_reviews(params, offset=0, per_page=100)
    max = 10000
    offset = 0
    finished = false
    claim_reviews = []
    while offset+per_page <= max && !finished
      response = Bot::Fetch.call_fetch_api(:get, 'claim_reviews', params.merge(per_page: per_page, offset: offset, include_raw: false))
      response.collect{|cr| claim_reviews << cr}
      offset += per_page
      finished = true if response.length < per_page
    end
    claim_reviews
  end

  def self.call_fetch_api(verb, endpoint, params = {})
    response = OpenStruct.new(body: '{}')
    if verb == :get
      query = []
      params.each do |key, value|
        query << "#{key}=#{value}"
      end
      query_string = query.join('&')
      uri = URI("#{CheckConfig.get('fetch_url')}/#{endpoint}?#{query_string}")
      response = Net::HTTP.get_response(uri)
    elsif [:post, :delete].include?(verb)
      uri = URI("#{CheckConfig.get('fetch_url')}/#{endpoint}")
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        klass = {
          post: Net::HTTP::Post,
          delete: Net::HTTP::Delete
        }[verb]
        request = klass.new(uri, 'Content-Type' => 'application/json')
        request.body = params.to_json
        response = http.request(request)
      end
    end
    JSON.parse(response.body)
  end

  # Class that handles only the importing
  # Mandatory fields in the imported ClaimReview: claim_review_headline, claim_review_url, created_at and id

  class Import
    def self.import_claim_reviews(installation_id, language = nil, force = false, maximum = nil)
      installation = TeamBotInstallation.find(installation_id)
      RequestStore.store[:skip_notifications] = true
      RequestStore.store[:skip_cached_field_update] = false
      User.current = user = installation.user
      Team.current = team = installation.team
      status_fallback = installation.get_status_fallback
      auto_publish_reports = installation.get_auto_publish_reports
      status_mapping = installation.get_status_mapping.blank? ? nil : JSON.parse(installation.get_status_mapping, { quirks_mode: true })
      Bot::Fetch.convert_service_name(installation.get_fetch_service_name).each do |service_name|
        service_info = Bot::Fetch.supported_services.find{ |s| s['service'] == service_name }
        if service_info['count'] > 0
          # Paginate by date in a way that we have more or less 1000 items per "page"
          n = (service_info['count'].to_f / 1000).ceil
          from = Time.parse(service_info['earliest']).yesterday
          to = Time.parse(service_info['latest']).tomorrow
          days = ((to - from) / 86400.0).ceil
          step = (days.to_f / n).ceil
          step = 1 if step == 0
          total = 0
          (from.to_i..to.to_i).step(step.days).each do |current_timestamp|
            from2 = Time.at(current_timestamp)
            to2 = from2 + step.days
            params = { service: service_name, start_time: from2.strftime('%Y-%m-%d'), end_time: to2.strftime('%Y-%m-%d')}
            params[:language] = language if !language.nil?
            Bot::Fetch.get_claim_reviews(params).each do |claim_review|
              next if !maximum.nil? && total >= maximum
              self.import_claim_review(claim_review, team.id, user.id, status_fallback, status_mapping, auto_publish_reports, force)
              total += 1
            end
          end
          CheckSentry.notify(Bot::Fetch::Error.new("[Fetch] The number of imported claim reviews (#{total}) is different from the expected (#{service_info['count']})")) if total != service_info['count']
        end
      end
    end

    def self.import_claim_review(claim_review, team_id, user_id, status_fallback, status_mapping, _auto_publish_reports, force = false)
      begin
        user = User.find(user_id)
        team = Team.find(team_id)
        Rails.cache.delete(self.semaphore_key(team_id, claim_review['identifier'])) if force
        unless self.already_imported?(claim_review, team)
          Rails.cache.write(self.semaphore_key(team_id, claim_review['identifier']), Time.now)
          ApplicationRecord.transaction do
            pm = self.create_project_media(team, user, claim_review)
            self.set_status(claim_review, pm, status_fallback, status_mapping)
            self.set_analysis(claim_review, pm)
            self.set_claim_and_fact_check(claim_review, pm, user, team)
            self.create_tags(claim_review, pm, user)
          end
        end
      rescue StandardError => e
        Rails.cache.delete(self.semaphore_key(team_id, claim_review['identifier']))
        CheckSentry.notify(e, context: 'Fetch Bot', claim_review: claim_review, team_id: team_id)
      end
    end

    def self.semaphore_key(team_id, id)
      "fetch:claim_review_imported:#{team_id}:#{id}"
    end

    def self.already_imported?(claim_review, team)
      id = claim_review['identifier']
      joins = "INNER JOIN annotations ON annotations.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias ON project_medias.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'"
      Rails.cache.read(self.semaphore_key(team.id, id)) || DynamicAnnotation::Field.joins(joins).where('project_medias.team_id' => team.id, 'field_name' => 'external_id', 'annotations.annotation_type' => 'verification_status').where('dynamic_annotation_fields_value(field_name, value) = ?', id.to_json).last.present?
    end

    def self.create_project_media(team, user, claim_review)
      ProjectMedia.create!(
        media: Claim.create!(quote: self.get_title(claim_review)),
        team: team,
        user: user,
        channel: { main: CheckChannels::ChannelCodes::FETCH },
        archived: CheckArchivedFlags::FlagCodes::FACTCHECK_IMPORT
      )
    end

    def self.get_title(claim_review)
      title = claim_review['headline'].blank? ? claim_review['claimReviewed'] : claim_review['headline']
      self.parse_text(title.to_s)
    end

    def self.get_summary(claim_review)
      url = claim_review['url'].to_s
      title = self.get_title(claim_review).to_s
      text = claim_review['text'].to_s.blank? ? claim_review['headline'] : claim_review['text']
      return '' if text.to_s == title.to_s || text.blank?
      summary = self.parse_text(text)
      summary.to_s.truncate(900 - title.size - url.size)
    end

    def self.set_claim_and_fact_check(claim_review, pm, user, team)
      current_user = User.current
      User.current = user
      cd = ClaimDescription.new
      cd.skip_check_ability = true
      cd.project_media = pm
      cd.description = claim_review['claimReviewed'].to_s.blank? ? '-' : self.parse_text(claim_review['claimReviewed'])
      cd.user = user
      cd.save!
      # Get FactCheck language
      fc_language = nil
      unless claim_review['inLanguage'].blank?
        languages = team.get_languages || ['en']
        fc_language = languages.include?(claim_review['inLanguage']) ? claim_review['inLanguage'] : nil
      end
      fc = FactCheck.new
      fc.skip_check_ability = true
      fc.claim_description = cd
      fc.title = self.get_title(claim_review).to_s
      fc.url = claim_review['url'].to_s
      fc.summary = self.get_summary(claim_review).to_s
      fc.tags = claim_review['keywords'].to_s.split(',').map(&:strip).reject{ |r| r.blank? }
      fc.user = user
      fc.language = fc_language
      fc.publish_report = true
      fc.report_status = 'published'
      fc.channel = 'imported'
      fc.save!
      User.current = current_user
    end

    def self.create_tags(claim_review, pm, user)
      current_user = User.current
      User.current = user
      tags = claim_review['keywords'].to_s.split(',').map(&:strip).reject{ |r| r.blank? }
      tags.each do |tag|
        Tag.create(tag: tag, annotator: user, annotated: pm, skip_check_ability: true)
      end
      User.current = current_user
    end

    def self.set_analysis(claim_review, pm)
      s = pm.last_status_obj
      s.skip_check_ability = true
      s.skip_notifications = true
      s.disable_es_callbacks = Rails.env.to_s == 'test'
      s.set_fields = {
        external_id: "#{claim_review['identifier']}:#{pm.team_id}", # The same external_id can exist across teams
        raw: claim_review.to_json
      }.to_json
      s.save!
    end

    def self.set_status(claim_review, pm, status_fallback, status_mapping)
      status = status_fallback
      if claim_review['reviewRating'] && status_mapping
        rating_value = claim_review.dig('reviewRating', 'alternateName') || claim_review.dig('reviewRating', 'ratingValue')
        mapped_status = status_mapping[rating_value.to_s] || status_mapping[rating_value.to_i]
        status = mapped_status unless mapped_status.blank?
      end
      s = pm.last_status_obj
      begin
        s.status = status
        s.save!
      rescue
        s.status = status_fallback
        s.save!
      end
    end

    def self.parse_text(text)
      CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(text.to_s))
    end
  end
end
