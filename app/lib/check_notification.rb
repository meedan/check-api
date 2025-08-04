module CheckNotification
  class InfoCodes
    SENT_TO_TRASH_BY_RULE = 1
    BANNED_SUBMITTER_BY_RULE = 3
    RELATED_TO_CONFIRMED_SIMILAR = 5
    RELATED_TO_SUGGESTED_SIMILAR = 6
    SENT_MESSAGE_TO_REQUESTORS_ON_STATUS_CHANGE = 7
    TAGGED_BY_RULE = 8
    ADD_WARNING_COVER_BY_RULE = 10
    ALL = %w(SENT_TO_TRASH_BY_RULE BANNED_SUBMITTER_BY_RULE RELATED_TO_CONFIRMED_SIMILAR RELATED_TO_SUGGESTED_SIMILAR SENT_MESSAGE_TO_REQUESTORS_ON_STATUS_CHANGE TAGGED_BY_RULE ADD_WARNING_COVER_BY_RULE)
  end

  class InfoMessages
    include CheckPusher

    def self.send(info, args={})
      begin
        args.each_pair { |key, value| args[key] = value.truncate(25) if value.is_a?(String) && !key.match(/link|url/) }
        info_message = { message: I18n.t("info.messages.#{info}".to_sym, **args), code: "CheckNotification::InfoCodes::#{info.upcase}".constantize }
        CheckPusher::Worker.perform_async(["check-api-session-channel-#{actor_session_id}"], 'info_message', info_message.to_json, actor_session_id)
      rescue StandardError => e
        Rails.logger.info "[CheckNotification] Exception sending notification to Pusher"
        CheckSentry.notify(e, params: info)
      end
    end
  end
end
