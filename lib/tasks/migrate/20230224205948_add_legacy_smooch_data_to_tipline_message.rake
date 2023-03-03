
# A helper class for migrating smooch_data from existing tiplines
# into the new TiplineMessage format
class MigratedTiplineMessageHelper
  class << self
    def requests(team_id, cutoff_time)
      relation = Annotation.where(annotation_type: 'smooch').joins("INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = annotations.id AND fs.field_name = 'smooch_data'")
        .where('t.id' => team_id)
        .where("annotations.created_at < ?", cutoff_time)
    end

    def project_media_requests(team_id, cutoff_time)
      base = requests(team_id, cutoff_time)
      base.joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id")
    end

    def team_requests(team_id, cutoff_time)
      base = requests(team_id, cutoff_time)
      base.joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND t.id = annotations.annotated_id")
    end

    def reports_received(team_id, cutoff_time)
      DynamicAnnotation::Field
        .where(field_name: 'smooch_report_received')
        .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = a.id AND fs.field_name = 'smooch_data'")
        .where('t.id' => team_id)
        .where("a.created_at < ?", cutoff_time)
    end

    def split_into_individual_messages(smooch_data)
      smooch_data['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY)
    end

    def approximate_conversations(team_id, req)
      tipline_messages = []
      smooch_data = begin JSON.parse(req.load.get_field_value('smooch_data')) rescue return tipline_messages end

      split_into_individual_messages(smooch_data).each_with_index do |message_text, index|
        external_id = index.zero? ? smooch_data['_id'] : "#{smooch_data['_id']}-#{index}"

        tm1 = MigratedTiplineMessage.from_smooch_annotation_data(
          smooch_data,
          team_id: team_id,
          direction: :incoming,
          legacy_smooch_message_text: message_text,
          external_id: external_id
        )
        tipline_messages << tm1

        tm2 = MigratedTiplineMessage.from_smooch_annotation_data(smooch_data, team_id: team_id, direction: :outgoing, external_id: "#{external_id}_sent")
        tipline_messages << tm2
      end

      tipline_messages
    end

    def append_to_cache(team_id)
      completed_ids = self.read_cache || []
      completed_ids << team_id
      Rails.cache.write("smooch_data_migration:completed_team_ids", completed_ids)
    end

    def read_cache
      Rails.cache.read("smooch_data_migration:completed_team_ids")
    end
  end
end

namespace :check do
  namespace :migrate do
    desc "Generate historic TiplineMessages from annotation data"
    task generate_tipline_messages: :environment do

      # A temporary constructor for loading in data from annotations,
      # used only for this import task
      #
      # Needs to be defined within the rake task in order to access TiplineMessage,
      # which requires the TiplineMessage class to be available in the environment
      # upon class definition
      class MigratedTiplineMessage < TiplineMessage
        class << self
          def from_smooch_annotation_data(msg, **attrs)
            msg = msg.with_indifferent_access

            attributes = {
              uid: msg['authorId'],
              external_id: msg['_id'],
              language: msg['language'],
              platform: Bot::Smooch.get_platform_from_message(msg, skip_store: true),
              sent_at: parse_timestamp(msg['received']),
              legacy_smooch_data: msg,
              imported_from_legacy_smooch_data: true,
            }.merge(attrs)

            new(attributes)
          end

          def from_tipline_subscription(tipline_subscription, sent_at, **attrs)
            language = attrs[:language] || tipline_subscription.language
            attributes = {
              external_id: "#{tipline_subscription.id}_#{language}_#{sent_at.to_i}_newsletter",
              team_id: tipline_subscription.team_id,
              event: 'newsletter',
              direction: :outgoing,
              language: language,
              platform: tipline_subscription.platform,
              sent_at: sent_at,
              uid: tipline_subscription.uid,
              legacy_smooch_data: {},
              imported_from_legacy_smooch_data: true
            }.merge(attrs)

            new(attributes)
          end
        end
      end

      task_started_at = Time.now
      # Time when we first began storing TiplineMessages, at which point we will have duplicated new
      # TiplineMessage data and old-version Annotation data
      tipline_message_cutover = MigratedTiplineMessage.where(imported_from_legacy_smooch_data: false).order(:created_at).first&.created_at
      cutoff_time = tipline_message_cutover || task_started_at
      puts "[#{Time.now}] Considering records created before #{cutoff_time}"

      # For any team that has Smooch tipline data
      tipline_team_ids = Team.
              joins(:project_medias).
              where(project_medias: { user: BotUser.smooch_user }).
              distinct.pluck(:id)

      completed_team_ids = MigratedTiplineMessageHelper.read_cache
      puts "[#{Time.now}] #{tipline_team_ids.length} teams found with data for active tiplines: #{tipline_team_ids}"
      if completed_team_ids
        remaining_team_ids = tipline_team_ids - completed_team_ids
        puts "[#{Time.now}] #{completed_team_ids} detected as completed. Starting at team_id: #{remaining_team_ids.first}"
      else
        remaining_team_ids = tipline_team_ids
      end

      remaining_team_ids.each_with_index do |team_id, index|
        puts "[#{Time.now}] Creating historic tipline messages for team with ID #{team_id}. (#{index + 1} / #{remaining_team_ids.length})"

        team = Team.find(team_id)

        # Messages sent to tipline from users, and estimated responses from tiplines
        MigratedTiplineMessageHelper.project_media_requests(team_id, cutoff_time).in_batches do |batch|
          tipline_messages = batch.map { |req| MigratedTiplineMessageHelper.approximate_conversations(team_id, req) }.flatten
          result = MigratedTiplineMessage.import(tipline_messages, on_duplicate_key_ignore: true)
          puts "[#{Time.now}] Saved #{result.ids.count} of #{tipline_messages.size} in this batch of project media requests"
        end
        MigratedTiplineMessageHelper.team_requests(team_id, cutoff_time).in_batches do |batch|
          tipline_messages = batch.map { |req| MigratedTiplineMessageHelper.approximate_conversations(team_id, req) }.flatten
          result = MigratedTiplineMessage.import(tipline_messages, on_duplicate_key_ignore: true)
          puts "[#{Time.now}] Saved #{result.ids.count} of #{tipline_messages.size} in this batch of team requests"
        end

        # Reports sent to users
        MigratedTiplineMessageHelper.reports_received(team_id, cutoff_time).in_batches do |batch|
          reports = batch.map do |f|
            annotation = f.is_a?(Annotation) ? f : f.annotation
            smooch_data = begin JSON.parse(annotation.load.get_field_value('smooch_data')) rescue next end
            MigratedTiplineMessage.from_smooch_annotation_data(smooch_data, external_id: "#{smooch_data["_id"]}_report", direction: :outgoing, event: 'fact_check_report_annotation', team_id: team_id)
          end.compact
          result = MigratedTiplineMessage.import(reports, on_duplicate_key_ignore: true)
          puts "[#{Time.now}] Saved #{result.ids.count} of #{reports.size} in this batch of reports sent"
        end

        # Newsletters sent to users
        tbi = TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last
        if tbi
          sent_newsletters_by_language = {}
          # Gather all sent newsletters, grouped by language
          Version.from_partition(team_id).
            where(whodunnit: BotUser.smooch_user.id.to_s, item_id: tbi.id.to_s, item_type: ['TeamUser', 'TeamBotInstallation']).
            where("created_at < ?", cutoff_time).each do |newsletter_version|
              begin
                YAML.load(JSON.parse(newsletter_version.object_after)['settings'])['smooch_workflows'].each do |smooch_workflow|
                  language = smooch_workflow['smooch_workflow_language']
                  sent_time = smooch_workflow['smooch_newsletter']['smooch_newsletter_last_sent_at']

                  # Attempt to parse the timestamp - if not valid then will hit rescue and continue
                  Time.parse(sent_time) unless sent_time.acts_like?(:time)

                  sent_newsletters_by_language[language] ||= []
                  sent_newsletters_by_language[language] << sent_time.to_s
                end
              rescue StandardError => e
                next
              end
          end

          # For each subscriber at the time a newsletter was sent to a given language,
          # create a record of an outgoing message
          newsletter_messages = []
          sent_newsletters_by_language.each do |language, sent_times|
            sent_times.uniq.each do |sent_time_string|
              sent_time = Time.parse(sent_time_string)
              subscriptions = TiplineSubscription.where(created_at: 100.years.ago..sent_time, language: language, team_id: team_id)

              newsletter_messages << subscriptions.map do |ts|
                tm = MigratedTiplineMessage.from_tipline_subscription(ts, sent_time)
              end
            end
          end
          newsletter_messages.flatten!

          result = MigratedTiplineMessage.import(newsletter_messages, on_duplicate_key_ignore: true)
          puts "[#{Time.now}] Saved #{result.ids.count} of #{newsletter_messages.size} in this batch of newsletters sent."
        end
        MigratedTiplineMessageHelper.append_to_cache(team_id)
      end

      puts "[#{Time.now}] Done in #{Time.now.to_i - task_started_at.to_i} seconds."
    end
  end
end
