# bundle exec rake check:data:statistics[start_year,start_month,end_year (0 = current year),end_month (0 = current month),group_by_month (0 = no grouping or 1 = grouping),workspace_slugs_as_a_dot_separated_values_string]

require 'open-uri'
include ActionView::Helpers::DateHelper

namespace :check do
  namespace :data do
    desc 'Generate some statistics about some workspaces'
    task statistics: :environment do |_t, params|
      def requests(slug, platform, start_date, end_date, language, type = nil)
        relation = Annotation
          .where(annotation_type: 'smooch')
          .joins("INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = annotations.id AND fs.field_name = 'smooch_data'")
          .where("fs.value_json->'source'->>'type' = ?", platform)
          .where("fs.value_json->>'language' = ?", language)
          .where('t.slug' => slug)
          .where('annotations.created_at' => start_date..end_date)
        unless type.nil?
          relation = relation
            .joins("INNER JOIN dynamic_annotation_fields fs2 ON fs2.annotation_id = annotations.id AND fs2.field_name = 'smooch_request_type'")
            .where('fs2.value' => type.to_json)
        end
        relation
      end

      def reports_received(slug, platform, start_date, end_date, language)
        DynamicAnnotation::Field
          .where(field_name: 'smooch_report_received')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = a.id AND fs.field_name = 'smooch_data'")
          .where('t.slug' => slug)
          .where("fs.value_json->'source'->>'type' = ?", platform)
          .where("fs.value_json->>'language' = ?", language)
          .where('dynamic_annotation_fields.created_at' => start_date..end_date)
      end

      def project_media_requests(slug, platform, start_date, end_date, language, type = nil)
        base = requests(slug, platform, start_date, end_date, language, type)
        base.joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id")
      end

      def team_requests(slug, platform, start_date, end_date, language)
        base = requests(slug, platform, start_date, end_date, language)
        base.joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND t.id = annotations.annotated_id")
      end

      def unique_requests_count(relation)
        relation.group("fs.value_json #>> '{source,originalMessageId}'").count.size
      end

      def get_statistics(start_date, end_date, slug, platform, language, outfile)
        platform_name = Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[platform]
        month = nil
        if start_date.month != end_date.month || start_date.year != end_date.year
          month = "#{Date::MONTHNAMES[start_date.month]} #{start_date.year} - #{Date::MONTHNAMES[end_date.month]} #{end_date.year}"
        else
          month = "#{Date::MONTHNAMES[start_date.month]} #{start_date.year}"
        end
        id = [slug, platform_name, language, month].join('-').downcase.gsub(/[_ ]+/, '-')
        data = [id, Team.find_by_slug(slug).name, platform_name, language, month]

        # Number of conversations
        # FIXME: Should be a new conversation only after 15 minutes of inactivity
        value1 = unique_requests_count(project_media_requests(slug, platform, start_date, end_date, language))
        value2 = team_requests(slug, platform, start_date, end_date, language).count
        conversations = value1 + value2
        data << conversations

        # Average number of conversations per day
        data << (conversations / (start_date.to_date..end_date.to_date).count).to_i

        # Number of newsletters sent
        # NOTE: For all platforms
        # NOTE: Only starting from June 1, 2022
        team = Team.find_by_slug(slug)
        number_of_newsletters = 0
        if end_date >= Time.parse('2022-06-01')
          tbi = TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last
          number_of_newsletters = Version.from_partition(team.id).where(whodunnit: BotUser.smooch_user.id.to_s, created_at: start_date..end_date, item_id: tbi.id.to_s, item_type: ['TeamUser', 'TeamBotInstallation']).collect do |v|
            begin
              workflow = YAML.load(JSON.parse(v.object_after)['settings'])['smooch_workflows'].select{ |w| w['smooch_workflow_language'] == language }.first
              workflow['smooch_newsletter']['smooch_newsletter_last_sent_at']
            rescue
              nil
            end
          end.reject{ |t| t.blank? }.collect{ |t| Time.parse(t.to_s).to_s }.uniq.size
        end

        # Number of newsletter subscribers
        number_of_subscribers = TiplineSubscription.where(created_at: start_date.ago(100.years)..end_date, platform: platform_name, language: language).where('teams.slug' => slug).joins(:team).count

        numbers_of_messages = []
        numbers_of_messages_sent = []
        project_media_requests(slug, platform, start_date, end_date, language).find_each do |a|
          n = JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
          numbers_of_messages_sent << n
          numbers_of_messages << n * 2
        end
        team_requests(slug, platform, start_date, end_date, language).find_each do |a|
          n = JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
          numbers_of_messages_sent << n
          numbers_of_messages << n * 2
        end
        search_results = project_media_requests(slug, platform, start_date, end_date, language, 'relevant_search_result_requests').count + project_media_requests(slug, platform, start_date, end_date, language, 'irrelevant_search_result_requests').count + project_media_requests(slug, platform, start_date, end_date, language, 'timeout_search_requests').count
        numbers_of_messages_sent = numbers_of_messages_sent.sum + search_results + (number_of_newsletters * number_of_subscribers)
        numbers_of_messages = numbers_of_messages.sum + search_results + (number_of_newsletters * number_of_subscribers)

        # Number of messages sent
        data << numbers_of_messages_sent

        # Average number of messages per day
        if numbers_of_messages == 0
          data << 0
        else
          data << (numbers_of_messages / (start_date.to_date..end_date.to_date).count).to_i
        end

        # Number of unique users
        uids = []
        project_media_requests(slug, platform, start_date, end_date, language).find_each do |a|
          uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
          uids << uid if !uid.nil? && !uids.include?(uid)
        end
        team_requests(slug, platform, start_date, end_date, language).find_each do |a|
          uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
          uids << uid if !uid.nil? && !uids.include?(uid)
        end
        data << uids.size

        # Number of returning users (at least one session in the current month, and at least one session in the last previous 2 months)
        data << DynamicAnnotation::Field.where(field_name: 'smooch_data', created_at: start_date.ago(2.months)..start_date).where("value_json->>'authorId' IN (?) AND value_json->>'language' = ?", uids, language).collect{ |f| f.value_json['authorId'] }.uniq.size

        # SEARCH
        # 1. All searches (2 + 3)
        # 2. Positive search results (4 + 5 + 6)
        # 3. Negative search results
        # 4. Relevant feedback
        # 5. Irrelevant feedback
        # 6. No feedback
        search4 = unique_requests_count(project_media_requests(slug, platform, start_date, end_date, language, 'relevant_search_result_requests'))
        search5 = project_media_requests(slug, platform, start_date, end_date, language, 'irrelevant_search_result_requests').count
        search6 = unique_requests_count(project_media_requests(slug, platform, start_date, end_date, language, 'timeout_search_requests'))
        search2 = search4 + search5 + search6
        search3 = project_media_requests(slug, platform, start_date, end_date, language, 'default_requests').count
        search1 = search2 + search3
        data << search1
        data << search2
        data << search3
        data << search4
        data << search5
        data << search6

        # Number of valid queries
        data << unique_requests_count(project_media_requests(slug, platform, start_date, end_date, language).where('pm.archived' => 0))

        # Number of new published reports created in Check (e.g., native, not imported)
        # NOTE: For all platforms
        data << Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).where("data LIKE '%language: #{language}%'").where("data LIKE '%state: published%'").where('annotations.annotator_id NOT IN (?)', [BotUser.fetch_user.id, BotUser.alegre_user.id]).count

        # Number of published imported reports
        # NOTE: For all languages and platforms
        data << Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date, 'annotations.annotator_id' => [BotUser.fetch_user.id, BotUser.alegre_user.id]).where("data LIKE '%state: published%'").count

        # Number of queries answered with a report
        data << reports_received(slug, platform, start_date, end_date, language).group('pm.id').count.size + project_media_requests(slug, platform, start_date, end_date, language, 'relevant_search_result_requests').group('pm.id').count.size

        # Number of reports sent to users
        data << reports_received(slug, platform, start_date, end_date, language).count + project_media_requests(slug, platform, start_date, end_date, language, 'relevant_search_result_requests').count

        # Number of unique users who received a report
        data << [reports_received(slug, platform, start_date, end_date, language) + project_media_requests(slug, platform, start_date, end_date, language, 'relevant_search_result_requests')].flatten.collect do |f|
          annotation = f.is_a?(Annotation) ? f : f.annotation
          JSON.parse(annotation.load.get_field_value('smooch_data'))['authorId']
        end.uniq.size

        # Average time to publishing
        times = []
        reports_received(slug, platform, start_date, end_date, language).find_each do |f|
          times << (f.created_at - f.annotation.created_at)
        end
        if times.size == 0
          data << '-'
        else
          avg = times.sum.to_f / times.size
          data << distance_of_time_in_words(avg)
        end

        # Number of newsletters sent
        # NOTE: For all platforms
        # NOTE: Only starting from June 1, 2022
        team = Team.find_by_slug(slug)
        if end_date < Time.parse('2022-06-01')
          data << '-'
        else
          data << number_of_newsletters
        end

        # Number of new newsletter subscriptions
        data << TiplineSubscription.where(created_at: start_date..end_date, platform: platform_name, language: language).where('teams.slug' => slug).joins(:team).count

        # Number of newsletter subscription cancellations
        data << Version.from_partition(team.id).where(created_at: start_date..end_date, team_id: team.id, item_type: 'TiplineSubscription', event_type: 'destroy_tiplinesubscription').where('object LIKE ?', "%#{platform_name}%").where('object LIKE ?', '%"language":"' + language + '"%').count

        # Current number of newsletter subscribers
        data << TiplineSubscription.where(created_at: start_date.ago(100.years)..end_date, platform: platform_name, language: language).where('teams.slug' => slug).joins(:team).count

        # Total number of imported reports
        # NOTE: For all languages and platforms
        # data << ProjectMedia.joins(:team).where('teams.slug' => slug, 'created_at' => start_date..end_date, 'user_id' => BotUser.fetch_user.id).count

        outfile.puts(data.join(','))
        data
      end

      def get_feed_statistics(pmids, feed, team, from, to)
        data = []
        data << Request.where(feed_id: feed.id, created_at: from..to).count
        data << ProjectMedia.where(id: pmids, team_id: team.id, updated_at: from..to).count
        data << ProjectMediaRequest.joins(:project_media, :request).where('project_medias.id' => pmids, 'project_medias.team_id' => team.id, 'requests.created_at' => from..to).where('requests.content != ?', '.').group(:request_id).count.size
        data << FactCheck.joins(claim_description: :project_media).where('project_medias.id' => pmids, 'project_medias.team_id' => team.id, 'fact_checks.created_at' => from..to).where.not(url: nil).count
        data
      end

      bucket_name = 'check-batch-task-statistics'
      region = 'eu-west-1'
      begin
        s3_client = Aws::S3::Client.new(region: region)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        puts "Please provide the AWS credentials."
        exit 1
      end

      def cache_team_data(team, header, rows)
        data = []
        rows.each do |row|
          entry = {}
          header.each_with_index do |column, i|
            entry[column] = row[i]
          end
          data << entry
        end
        Rails.cache.write("data:report:#{team.id}", data)
      end

      def object_uploaded?(s3_client, bucket_name, object_key, file_path)
        response = s3_client.put_object(
          acl: 'public-read',
          key: object_key,
          body: File.read(file_path),
          bucket: bucket_name,
          content_type: 'text/csv'
        )

        response = s3_client.put_object(
          bucket: bucket_name,
          key: object_key,
          body: File.read(file_path)
        )
        if response.etag
          #s3_client.put_object_acl(acl: 'public-read', key: file_path, bucket: bucket_name)
          return true
        else
          return false
        end
      rescue StandardError => e
        puts "Error uploading S3 object: #{e.message}"
        return false
      end

      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      args = params.to_a
      start_year = args[0].to_i
      start_month = args[1].to_i
      end_year = args[2].to_i
      end_year = Time.now.year if end_year == 0
      end_month = args[3].to_i
      end_month = Time.now.month if end_month == 0
      group_by_month = args[4].to_i
      slugs = args[5].to_s.split('.')
      if slugs.empty?
        puts 'Please provide a list of workspace slugs'
      else
        outfile = File.open('/tmp/statistics.csv', 'w')
        header = [
          'ID',
          'Org',
          'Platform',
          'Language',
          'Month',
          'Conversations',
          'Average number of conversations per day',
          'Number of messages sent',
          'Average messages per day',
          'Unique users',
          'Returning users',
          'Searches',
          'Positive searches',
          'Negative searches',
          'Search feedback positive',
          'Search feedback negative',
          'Search no feedback',
          'Valid new requests',
          'Published native reports',
          'Published imported reports',
          'Requests answered with a report',
          'Reports sent to users',
          'Unique users who received a report',
          'Average (median) response time',
          'Unique newsletters sent',
          'New newsletter subscriptions',
          'Newsletter cancellations',
          'Current subscribers'
        ]
        outfile.puts(header.join(','))

        slugs.each do |slug|
          team = Team.find_by_slug(slug)
          team_rows = []
          TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last.smooch_enabled_integrations.keys.each do |platform|
            team.get_languages.each do |language|
              if group_by_month == 1
                (start_year..end_year).to_a.each do |year|
                  year_start_month = 1
                  year_start_month = start_month if year == start_year
                  year_end_month = 12
                  year_end_month = end_month if year == end_year
                  (year_start_month..year_end_month).to_a.each do |month|
                    time = Time.parse("#{year}-#{month}-01")
                    next if team.created_at > time.end_of_month
                    team_rows << get_statistics(time.beginning_of_month, time.end_of_month, slug, platform, language, outfile)
                  end
                end
              else
                team_rows << get_statistics(Time.parse("#{start_year}-#{start_month}-01"), Time.parse("#{end_year}-#{end_month}-01").end_of_month, slug, platform, language, outfile)
              end
            end
          end
          cache_team_data(team, header, team_rows)
        end
        outfile.close

        ['day', 'week'].each do |period|
          outfile = File.open("/tmp/feed_#{period}.csv", 'w')
          header = ['Feed', 'Feed type', 'Workspace', period.capitalize, 'Number of feed requests', 'Number of items shared', 'Number of requests associated with any items shared', 'Number of fact-checks published with URL']
          outfile.puts(header.join(','))
          Feed.all.each do |feed|
            next if feed.teams.empty?
            Team.current = feed.teams.first
            pmids = CheckSearch.new({ feed_id: feed.id, eslimit: 10000 }.to_json).medias.map(&:id).uniq
            Team.current = nil
            feed_type = (feed.published ? 'Distribution' : 'Collaborative')
            feed.teams.each do |team|
              date = nil
              begin
                from = nil
                to = nil
                # Cold start
                if date.nil?
                  from = ProjectMedia.first.created_at
                  to = feed.created_at.end_of_day
                  date = to
                else
                  from = date.send("beginning_of_#{period}")
                  to = date.send("end_of_#{period}")
                end
                row = [feed.name, feed_type, team.name, date.strftime('%Y-%m-%d')]
                row << get_feed_statistics(pmids, feed, team, from, to)
                outfile.puts(row.flatten.join(','))
                date += 1.send(period)
              end while date <= Time.now
            end
          end
          outfile.close
        end

        ['statistics', 'feed_day', 'feed_week'].each do |outfile|
          if defined?(ENV.fetch('STATISTICS_S3_DIR'))
            puts "Starting upload for #{outfile}.csv"
            file_path = "/tmp/#{outfile}.csv"
            object_key = "#{ENV['STATISTICS_S3_DIR']}/#{outfile}.csv"
            if object_uploaded?(s3_client, bucket_name, object_key, file_path)
              puts "Uploaded #{outfile}.csv"
            else
              puts "Error uploading #{outfile}.csv to S3. Check credentials?"
            end
          end
        end
      end
      ActiveRecord::Base.logger = old_logger
    end
  end
end
