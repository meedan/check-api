module CheckStatistics
  class << self
    def requests(team_id, platform, start_date, end_date, language, type = nil)
      relation = Annotation
        .where(annotation_type: 'smooch')
        .joins("INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = annotations.id AND fs.field_name = 'smooch_data'")
        .where("fs.value_json->'source'->>'type' = ?", platform)
        .where("fs.value_json->>'language' = ?", language)
        .where('t.id' => team_id)
        .where('annotations.created_at' => start_date..end_date)
      unless type.nil?
        relation = relation
          .joins("INNER JOIN dynamic_annotation_fields fs2 ON fs2.annotation_id = annotations.id AND fs2.field_name = 'smooch_request_type'")
          .where('fs2.value' => type.to_json)
      end
      relation
    end

    def reports_received(team_id, platform, start_date, end_date, language)
      DynamicAnnotation::Field
        .where(field_name: 'smooch_report_received')
        .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = a.id AND fs.field_name = 'smooch_data'")
        .where('t.id' => team_id)
        .where("fs.value_json->'source'->>'type' = ?", platform)
        .where("fs.value_json->>'language' = ?", language)
        .where('dynamic_annotation_fields.created_at' => start_date..end_date)
    end

    def project_media_requests(team_id, platform, start_date, end_date, language, type = nil)
      base = requests(team_id, platform, start_date, end_date, language, type)
      base.joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id")
    end

    def team_requests(team_id, platform, start_date, end_date, language)
      base = requests(team_id, platform, start_date, end_date, language)
      base.joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND t.id = annotations.annotated_id")
    end

    def unique_requests_count(relation)
      relation.group("fs.value_json #>> '{source,originalMessageId}'").count.size
    end

    def get_statistics(start_date, end_date, team_id, platform, language)
      # attributes in statistics hash must correspond to database fields on MonthlyTeamStatistic
      statistics = {}
      tracing_attributes = { "app.team.id" => team_id, "app.attr.platform" => platform, "app.attr.language" => language}
      CheckTracer.in_span('CheckStatistics.get_statistics', attributes: tracing_attributes) do
        team = Team.find(team_id)

        platform_name = Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[platform]
        statistics = {
          platform: platform_name,
          language: language,
          start_date: start_date,
          end_date: end_date,
        }

        conversations = nil
        CheckTracer.in_span('CheckStatistics#conversations', attributes: tracing_attributes) do
          # Number of conversations
          # FIXME: Should be a new conversation only after 15 minutes of inactivity
          value1 = unique_requests_count(project_media_requests(team_id, platform, start_date, end_date, language))
          value2 = team_requests(team_id, platform, start_date, end_date, language).count
          conversations = value1 + value2
          statistics[:conversations] = conversations
        end

        number_of_newsletters = 0
        CheckTracer.in_span('CheckStatistics#unique_newsletters_sent', attributes: tracing_attributes) do
          # Number of newsletters sent
          # NOTE: For all platforms
          # NOTE: Only starting from June 1, 2022
          if end_date >= Time.parse('2022-06-01')
            tbi = TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last
            number_of_newsletters = Version.from_partition(team_id).where(whodunnit: BotUser.smooch_user.id.to_s, created_at: start_date..end_date, item_id: tbi.id.to_s, item_type: ['TeamUser', 'TeamBotInstallation']).collect do |v|
              begin
                workflow = YAML.load(JSON.parse(v.object_after)['settings'])['smooch_workflows'].select{ |w| w['smooch_workflow_language'] == language }.first
                workflow['smooch_newsletter']['smooch_newsletter_last_sent_at']
              rescue
                nil
              end
            end.reject{ |t| t.blank? }.collect{ |t| Time.parse(t.to_s).to_s }.uniq.size
            statistics[:unique_newsletters_sent] = end_date
          end
        end

        current_newsletter_subscribers = nil
        CheckTracer.in_span('CheckStatistics#current_subscribers', attributes: tracing_attributes) do
          # Current number of newsletter subscribers
          current_newsletter_subscribers = TiplineSubscription.where(created_at: start_date.ago(100.years)..end_date, platform: platform_name, language: language).where('teams.id' => team_id).joins(:team).count
          statistics[:current_subscribers] = current_newsletter_subscribers
        end

        CheckTracer.in_span('CheckStatistics#average_messages_per_day', attributes: tracing_attributes) do
          numbers_of_messages = []
          project_media_requests(team_id, platform, start_date, end_date, language).find_each do |a|
            n = JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
            numbers_of_messages << n * 2
          end
          team_requests(team_id, platform, start_date, end_date, language).find_each do |a|
            n = JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
            numbers_of_messages << n * 2
          end
          search_results = project_media_requests(team_id, platform, start_date, end_date, language, 'relevant_search_result_requests').count + project_media_requests(team_id, platform, start_date, end_date, language, 'irrelevant_search_result_requests').count + project_media_requests(team_id, platform, start_date, end_date, language, 'timeout_search_requests').count

          # Average number of messages per day
          number_of_messages = numbers_of_messages.sum + search_results + (number_of_newsletters * current_newsletter_subscribers)
          if number_of_messages == 0
            statistics[:average_messages_per_day] = 0
          else
            statistics[:average_messages_per_day] = (number_of_messages / (start_date.to_date..end_date.to_date).count).to_i
          end
        end

        uids = []
        CheckTracer.in_span('CheckStatistics#unique_users', attributes: tracing_attributes) do
          # Number of unique users
          project_media_requests(team_id, platform, start_date, end_date, language).find_each do |a|
            uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
            uids << uid if !uid.nil? && !uids.include?(uid)
          end
          team_requests(team_id, platform, start_date, end_date, language).find_each do |a|
            uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
            uids << uid if !uid.nil? && !uids.include?(uid)
          end
          statistics[:unique_users] = uids.size
        end

        CheckTracer.in_span('CheckStatistics#returning_users', attributes: tracing_attributes) do
          # Number of returning users (at least one session in the current month, and at least one session in the last previous 2 months)
          statistics[:returning_users] = DynamicAnnotation::Field.where(field_name: 'smooch_data', created_at: start_date.ago(2.months)..start_date).where("value_json->>'authorId' IN (?) AND value_json->>'language' = ?", uids, language).collect{ |f| f.value_json['authorId'] }.uniq.size
        end

        CheckTracer.in_span('CheckStatistics#valid_new_requests', attributes: tracing_attributes) do
          # Number of valid queries
          statistics[:valid_new_requests] = unique_requests_count(project_media_requests(team_id, platform, start_date, end_date, language).where('pm.archived' => 0))
        end

        CheckTracer.in_span('CheckStatistics#published_native_reports', attributes: tracing_attributes) do
          # Number of new published reports created in Check (e.g., native, not imported)
          # NOTE: For all platforms
          statistics[:published_native_reports] = Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.id' => team_id).where('annotations.created_at' => start_date..end_date).where("data LIKE '%language: #{language}%'").where("data LIKE '%state: published%'").where('annotations.annotator_id NOT IN (?)', [BotUser.fetch_user.id, BotUser.alegre_user.id]).count
        end

        CheckTracer.in_span('CheckStatistics#published_imported_reports', attributes: tracing_attributes) do
          # Number of published imported reports
          # NOTE: For all languages and platforms
          statistics[:published_imported_reports] = Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.id' => team_id).where('annotations.created_at' => start_date..end_date, 'annotations.annotator_id' => [BotUser.fetch_user.id, BotUser.alegre_user.id]).where("data LIKE '%state: published%'").count
        end

        CheckTracer.in_span('CheckStatistics#requests_answerwed_with_report', attributes: tracing_attributes) do
          # Number of queries answered with a report
          statistics[:requests_answered_with_report] = reports_received(team_id, platform, start_date, end_date, language).group('pm.id').count.size + project_media_requests(team_id, platform, start_date, end_date, language, 'relevant_search_result_requests').group('pm.id').count.size
        end

        CheckTracer.in_span('CheckStatistics#reports_sent_to_users', attributes: tracing_attributes) do
          # Number of reports sent to users
          statistics[:reports_sent_to_users] = reports_received(team_id, platform, start_date, end_date, language).count + project_media_requests(team_id, platform, start_date, end_date, language, 'relevant_search_result_requests').count
        end

        CheckTracer.in_span('CheckStatistics#unique_users_who_received_report', attributes: tracing_attributes) do
          # Number of unique users who received a report
          statistics[:unique_users_who_received_report] = [reports_received(team_id, platform, start_date, end_date, language) + project_media_requests(team_id, platform, start_date, end_date, language, 'relevant_search_result_requests')].flatten.collect do |f|
            annotation = f.is_a?(Annotation) ? f : f.annotation
            JSON.parse(annotation.load.get_field_value('smooch_data'))['authorId']
          end.uniq.size
        end

        CheckTracer.in_span('CheckStatistics#median_response_time', attributes: tracing_attributes) do
          # Average time to publishing
          times = []
          reports_received(team_id, platform, start_date, end_date, language).find_each do |f|
            times << (f.created_at - f.annotation.created_at)
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
