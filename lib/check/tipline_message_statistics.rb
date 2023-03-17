module Check
  class TiplineMessageStatistics
    def initialize(team_id)
      @team_id = team_id
      @conversation_start_index = nil
      reset_monthly_conversations!
    end

    delegate :cache_read, :cache_key, :cache_reset, :date_to_string, to: :class

    # Helper methods for clearing and reading from caches, for troubleshooting
    # cache_write is kept private, since it should only be used by this class
    class << self
      def reset_conversation_caches
        Rails.cache.delete_matched(/check:statistics:conversations:index:/)
      end

      def cache_read(uid, language, platform)
        Rails.cache.read(cache_key(uid, language, platform))
      end

      def cache_reset(uid, language, platform)
        Rails.cache.delete(cache_key(uid, language, platform))
      end

      def cache_key(uid, language, platform)
        "check:statistics:conversations:index:#{uid}-#{language}-#{platform}"
      end

      def date_to_string(date)
        date.strftime('%c')
      end
    end

    # A note on arguments:
    # - `platform`` wants to be human readable platform_name, e.g. WhatsApp instead of whatsapp
    # - `range_start` should be beginning of the month we want to return a calculation for
    # - `range_end` should be the end of the same month above that we want to return a calculation for, or partial time if that month is in-progress
    # - `earliest_record` will always be April 1, 2023 in real environments because that's when we start using this model
    #     to calculate conversations. however, we need a way to test it before that date so want to be able to pass override
    def monthly_conversations(platform, language, range_start, range_end, earliest_record = DateTime.new(2023,4,1))
      monthly_uids = TiplineMessage.where(team_id: @team_id, language: language, platform: platform, sent_at: range_start..range_end).pluck(:uid).uniq
      monthly_convos = 0

      monthly_uids.each do |uid|
        cached_convo_index = cache_read(uid, language, platform)
        messages = TiplineMessage.where(uid: uid, language: language, platform: platform, sent_at: (cached_convo_index || earliest_record)..range_end).order(:sent_at)
        next unless messages.any?

        @conversation_start_index = cached_convo_index || messages.first.sent_at

        reset_monthly_conversations!
        track_conversation!(@conversation_start_index)

        # find_each does not respect a given sort order in Rails 5 (we would want by sent_at asc), and instead returns
        # records sequentially by ID. This could cause issues when we have race conditions or messages sent
        # in quick succession. To get around this, we pull in batches, order that batch, and then iterate.
        messages.in_batches do |message_relation|
          message_relation.order(:sent_at).each do |message|
            next unless message.sent_at >= (@conversation_start_index + 24.hours)

            track_conversation!(message.sent_at)
            @conversation_start_index = message.sent_at
          end
        end
        monthly_convos += @monthly_conversations[date_to_string(range_start)].length

        # Mark the most recent conversation start we got to on this round.
        # Only update cache when calculating full months, since we'll want to re-calculate partial months.
        cache_write(uid, language, platform, @conversation_start_index) if range_end == range_start.end_of_month
      end

      monthly_convos
    end

    private

    def cache_write(uid, language, platform, time)
      Rails.cache.write(cache_key(uid, language, platform), time)
    end

    def track_conversation!(conversation_start)
      month_key = date_to_string(conversation_start.beginning_of_month)
      @monthly_conversations[month_key] << conversation_start
    end

    def reset_monthly_conversations!
      @monthly_conversations = Hash.new{|h,k| h[k] = [] }
    end
  end
end
