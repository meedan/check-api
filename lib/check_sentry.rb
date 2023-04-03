class CheckSentry
  class << self
    def notify(e, data = {})
      Rails.logger.error e

      # .with_scope sets contextual information only for this send
      Sentry.with_scope do |scope|
        scope.set_context('application', data)
        Sentry.capture_exception(e)
      end
    end

    def set_user_info(id, team_id: nil, api_key_id: nil)
      Sentry.set_user(id: id)

      if team_id || api_key_id
        # .configure_scope sets contextual information for entire event lifecycle
        Sentry.configure_scope do |scope|
          scope.set_context('application', {'user.team_id' => team_id, 'api_key_id' => api_key_id})
        end
      end
    end
  end
end
