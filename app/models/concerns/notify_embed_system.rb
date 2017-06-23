require 'active_support/concern'
require 'check_bridge_embed'

module NotifyEmbedSystem
  extend ActiveSupport::Concern

  included do
    after_create :notify_embed_system_created, if: :notify_created?
    after_update :notify_embed_system_updated, if: :notify_updated?
    after_destroy :notify_embed_system_destroyed, if: :notify_destroyed?

    protected

    def notify_embed_system(event, object)
      url = self.notification_uri(event)
      Check::BridgeEmbed.notify(notify_embed_system_payload(event,object), url)
    end

    private

    def notify_embed_system_created
      self.delay_for(1.second).notify_embed_system('created', self.notify_embed_system_created_object)
    end

    def notify_embed_system_updated
      self.delay_for(1.second).notify_embed_system('updated', self.notify_embed_system_updated_object)
    end

    def notify_embed_system_destroyed
      self.delay_for(1.second).notify_embed_system('destroyed', nil)
    end
  end
end
