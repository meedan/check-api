require 'active_support/concern'

module SmoochCapi
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_capi_request?(request)
      valid = false
      if request.params['hub.mode'] == 'subscribe'
        valid = self.verified_capi_installation?(request.params['hub.verify_token'])
      end
      RequestStore.store[:smooch_bot_provider] = 'CAPI' if valid
      valid
    end

    def verified_capi_installation?(verify_token)
      self.get_installation do |i|
        verify_token == i.settings.with_indifferent_access['capi_verify_token'].to_s
      end.present?
    end

    def preprocess_capi_message(body)
      # If body is empty and the request is valid, then this is a webhook verification
      if body.empty?
        {
          trigger: 'capi:verification',
          app: {
            '_id': ''
          },
          version: 'v1.1',
          messages: [],
          appUser: {
            '_id': '',
            'conversationStarted': true
          }
        }.with_indifferent_access
      end
    end
  end
end
