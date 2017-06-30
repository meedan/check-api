require 'active_support/concern'
require 'check_bridge_embed'

module NotifyEmbedSystem
  extend ActiveSupport::Concern

  included do
    after_create :notify_embed_system_created, if: :notify_created?, unless: :disabled?
    after_update :notify_embed_system_updated, if: :notify_updated?, unless: :disabled?
    after_destroy :notify_embed_system_destroyed, if: :notify_destroyed?, unless: :disabled?

    protected

    def notify_embed_system(event, object)
      url = self.notification_uri(event)
      Check::BridgeEmbed.notify(notify_embed_system_payload(event,object), url)
    end

    private

    def notify_embed_system_created
      raise 'here'
      self.delay_for(1.second).notify_embed_system('created', self.notify_embed_system_created_object)
    end

    def notify_embed_system_updated
      self.delay_for(1.second).notify_embed_system('updated', self.notify_embed_system_updated_object)
    end

    def notify_embed_system_destroyed
      self.delay_for(1.second).notify_embed_system('destroyed', nil)
    end

    def disabled?
      CONFIG['bridge_reader_url_private'].blank? || CONFIG['bridge_reader_url'].blank? || CONFIG['bridge_reader_token'].blank?
    end
  end
end
