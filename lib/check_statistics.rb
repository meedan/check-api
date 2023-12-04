module CheckStatistics
  class WhatsAppInsightsApiError < ::StandardError; end

  class << self
    def requests(team_id, platform, start_date, end_date, language, type = nil)
      conditions = {
        created_at: start_date..end_date,
        team_id: team_id,
        language: language,
        platform: platform
      }
      conditions[:smooch_request_type] = type unless type.nil?
      TiplineRequest.where(conditions)
    end

    def reports_received(team_id, platform, start_date, end_date, language)
      TiplineRequest
        .where(team_id: team_id, language: language, created_at: start_date..end_date, platform: platform)
        .where('smooch_report_received_at IS NOT NULL')
    end

    def project_media_requests(team_id, platform, start_date, end_date, language, type = nil)
      base = requests(team_id, platform, start_date, end_date, language, type)
      base.where(associated_type: 'ProjectMedia')
    end

    def team_requests(team_id, platform, start_date, end_date, language)
      base = requests(team_id, platform, start_date, end_date, language)
      base.where(associated_type: 'Team')
    end

    def unique_requests_count(relation)
      relation.group("smooch_data #>> '{source,originalMessageId}'").count.size
    end

    def number_of_newsletters_sent(team_id, start_date, end_date, language)
      return unless end_date >= Time.parse('2022-06-01')

      smooch = BotUser.smooch_user
      tbi = TeamBotInstallation.where(team_id: team_id, user: smooch).last
      return unless tbi

      times = Version.from_partition(team_id).where(whodunnit: smooch.id.to_s, created_at: start_date..end_date, item_id: tbi.id.to_s, item_type: ['TeamUser', 'TeamBotInstallation']).collect do |v|
        begin
          workflow = YAML.load(JSON.parse(v.object_after)['settings'])['smooch_workflows'].select{ |w| w['smooch_workflow_language'] == language }.first
          workflow['smooch_newsletter']['smooch_newsletter_last_sent_at']
        rescue
          nil
        end
      end.reject{ |t| t.blank? }.collect{ |t| Time.parse(t.to_s) }.select{ |t| t >= start_date && t <= end_date }.collect{ |t| t.to_s }.uniq
      old_count = times.size

      newsletter = TiplineNewsletter.where(team_id: team_id, language: language).last
      new_count = newsletter.nil? ? 0 : TiplineNewsletterDelivery.where(tipline_newsletter: newsletter, created_at: start_date..end_date).count

      old_count + new_count
    end

    def number_of_whatsapp_conversations(team_id, start_date, end_date)
      from = start_date.to_datetime.to_i
      to = end_date.to_datetime.to_i

      # Cache it so we don't recalculate when grabbing the statistics for different languages
      Rails.cache.fetch("check_statistics:whatsapp_conversations:#{team_id}:#{from}:#{to}", expires_in: 12.hours, skip_nil: true) do
        response = OpenStruct.new({ body: nil, code: 0 })
        begin
          tbi = TeamBotInstallation.where(team_id: team_id, user: BotUser.smooch_user).last

          # Only available for tiplines using WhatsApp Cloud API
          unless tbi&.get_capi_whatsapp_business_account_id.blank?
            uri = URI(URI.join('https://graph.facebook.com/v17.0/', tbi.get_capi_whatsapp_business_account_id.to_s))
            params = {
              fields: "conversation_analytics.start(#{from}).end(#{to}).granularity(DAILY).phone_numbers(#{tbi.get_capi_phone_number})",
              access_token: tbi.get_capi_permanent_token
            }
            uri.query = Rack::Utils.build_query(params)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            request = Net::HTTP::Get.new(uri.request_uri, 'Content-Type' => 'application/json')
            response = http.request(request)
            raise 'Unexpected response' if response.code.to_i >= 300
            data = JSON.parse(response.body)
            count = 0
            data['conversation_analytics']['data'][0]['data_points'].each do |data_point|
              count += data_point['conversation']
            end
            count
          else
            nil
          end

        rescue StandardError => e
          error_info = { error_message: e.message, response_code: response.code, response_body: response.body, team_id: team_id, start_date: start_date, end_date: end_date }
          CheckSentry.notify(WhatsAppInsightsApiError.new('Could not get WhatsApp conversations statistics'), **error_info)
          nil
        end
      end
    end

    def get_statistics(start_date, end_date, team_id, platform, language, tracing_attributes = {})
      # attributes in statistics hash must correspond to database fields on MonthlyTeamStatistic
      statistics = {}
      CheckTracer.in_span('CheckStatistics.get_statistics', attributes: tracing_attributes) do
        team = Team.find(team_id)

        statistics = {
          platform: platform,
          language: language,
          start_date: start_date,
          end_date: end_date,
        }
        platform_name = Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[platform]

        number_of_newsletters = nil
        CheckTracer.in_span('CheckStatistics#unique_newsletters_sent', attributes: tracing_attributes) do
          # Number of newsletters sent
          # NOTE: For all platforms
          # NOTE: Only starting from June 1, 2022
          number_of_newsletters = number_of_newsletters_sent(team_id, start_date, end_date, language)
          statistics[:unique_newsletters_sent] = number_of_newsletters
        end

        current_newsletter_subscribers = nil
        CheckTracer.in_span('CheckStatistics#current_subscribers', attributes: tracing_attributes) do
          # Current number of newsletter subscribers
          current_newsletter_subscribers = TiplineSubscription.where(created_at: start_date.ago(100.years)..end_date, platform: platform_name, language: language).where('teams.id' => team_id).joins(:team).count
          statistics[:current_subscribers] = current_newsletter_subscribers
        end

        uids = []
        CheckTracer.in_span('CheckStatistics#unique_users', attributes: tracing_attributes) do
          # Number of unique users
          project_media_requests(team_id, platform, start_date, end_date, language).find_each do |tr|
            uid = tr.tipline_user_uid
            uids << uid if !uid.nil? && !uids.include?(uid)
          end
          team_requests(team_id, platform, start_date, end_date, language).find_each do |tr|
            uid = tr.tipline_user_uid
            uids << uid if !uid.nil? && !uids.include?(uid)
          end
          statistics[:unique_users] = uids.size
        end

        CheckTracer.in_span('CheckStatistics#returning_users', attributes: tracing_attributes) do
          # Number of returning users (at least one session in the current month, and at least one session in the last previous 2 months)
          statistics[:returning_users] = TiplineRequest.where(created_at: start_date.ago(2.months)..start_date)
          .where(tipline_user_uid: uids, language: language).map(&:tipline_user_uid).uniq.size
        end

        CheckTracer.in_span('CheckStatistics#reports_sent_to_users', attributes: tracing_attributes) do
          # Number of reports sent to users
          statistics[:reports_sent_to_users] = reports_received(team_id, platform, start_date, end_date, language).count + project_media_requests(team_id, platform, start_date, end_date, language, 'relevant_search_result_requests').count
        end

        CheckTracer.in_span('CheckStatistics#unique_users_who_received_report', attributes: tracing_attributes) do
          # Number of unique users who received a report
          statistics[:unique_users_who_received_report] = [reports_received(team_id, platform, start_date, end_date, language) + project_media_requests(team_id, platform, start_date, end_date, language, 'relevant_search_result_requests')].flatten.collect do |tr|
            tr.tipline_user_uid
          end.uniq.size
        end

        CheckTracer.in_span('CheckStatistics#median_response_time', attributes: tracing_attributes) do
          # Average time to publishing
          times = []
          reports_received(team_id, platform, start_date, end_date, language).find_each do |tr|
            # TODO: review with Caio
            times << (tr.updated_at - tr.created_at)
          end
          median_response_time_in_seconds = times.size == 0 ? nil : times.sum.to_f / times.size
          statistics[:median_response_time] = median_response_time_in_seconds
        end

        CheckTracer.in_span('CheckStatistics#new_newsletter_subscriptions', attributes: tracing_attributes) do
          # Number of new newsletter subscriptions
          # We were not storing versions for created TiplineSubscription after they got deleted
          if end_date < Time.parse('2023-01-01')
            statistics[:new_newsletter_subscriptions] = TiplineSubscription.where(created_at: start_date..end_date, platform: platform_name, language: language).where('teams.id' => team_id).joins(:team).count
          else
            statistics[:new_newsletter_subscriptions] = Version.from_partition(team_id).where(created_at: start_date..end_date, team_id: team_id, item_type: 'TiplineSubscription', event_type: 'create_tiplinesubscription').where('object_after LIKE ?', "%#{platform_name}%").where('object_after LIKE ?', '%"language":"' + language + '"%').count
          end
        end

        CheckTracer.in_span('CheckStatistics#newsletter_cancellations', attributes: tracing_attributes) do
          # Number of newsletter subscription cancellations
          statistics[:newsletter_cancellations] = Version.from_partition(team_id).where(created_at: start_date..end_date, team_id: team_id, item_type: 'TiplineSubscription', event_type: 'destroy_tiplinesubscription').where('object LIKE ?', "%#{platform_name}%").where('object LIKE ?', '%"language":"' + language + '"%').count
        end

        CheckTracer.in_span('CheckStatistics#newsletters_delivered', attributes: tracing_attributes) do
          # Number of newsletters effectively delivered, accounting for user errors for each platform
          statistics[:newsletters_delivered] = TiplineMessage.where(created_at: start_date..end_date, team_id: team_id, platform: platform_name, language: language, direction: 'outgoing', state: 'delivered', event: 'newsletter').count
        end

        CheckTracer.in_span('CheckStatistics#whatsapp_conversations', attributes: tracing_attributes) do
          statistics[:whatsapp_conversations] = number_of_whatsapp_conversations(team_id, start_date, end_date) if platform_name == 'WhatsApp'
        end

        CheckTracer.in_span('CheckStatistics#published_reports', attributes: tracing_attributes) do
          # NOTE: For all languages and platforms
          statistics[:published_reports] = Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'").where('pm.team_id' => team_id).where('annotations.created_at' => start_date..end_date).where("data LIKE '%state: published%'").count
        end

        CheckTracer.in_span('CheckStatistics#positive_searches', attributes: tracing_attributes) do
          # Tipline queries that return results
          relevant_results = project_media_requests(team_id, platform, start_date, end_date, language, 'relevant_search_result_requests').count
          irrelevant_results = project_media_requests(team_id, platform, start_date, end_date, language, 'irrelevant_search_result_requests').count
          ignored_results = project_media_requests(team_id, platform, start_date, end_date, language, 'timeout_search_requests').count
          statistics[:positive_searches] = relevant_results + irrelevant_results + ignored_results
        end

        CheckTracer.in_span('CheckStatistics#negative_searches', attributes: tracing_attributes) do
          # Tipline queries that don't return results
          statistics[:negative_searches] = project_media_requests(team_id, platform, start_date, end_date, language, 'default_requests').count
        end

        CheckTracer.in_span('CheckStatistics#newsletters_sent', attributes: tracing_attributes) do
          # NOTE: For all platforms
          statistics[:newsletters_sent] = TiplineNewsletterDelivery.where(created_at: start_date..end_date).joins(:tipline_newsletter).where('tipline_newsletters.team_id' => team_id, 'tipline_newsletters.language' => language).sum(:recipients_count)
        end
      end
      statistics
    end

    def cache_team_data(team_id, header, rows)
      data = []
      rows.each do |row|
        entry = {}
        header.each_with_index do |column, i|
          entry[column] = row[i]
        end
        data << entry
      end
      Rails.cache.write("data:report:#{team_id}", data)
    end
  end
end
