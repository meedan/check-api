require 'active_support/concern'

module SmoochResources
  extend ActiveSupport::Concern

  module ClassMethods
    # This is the method called by the Smooch Bot
    def send_resource_to_user(uid, workflow, resource_uuid, language)
      resource = TiplineResource.where(uuid: resource_uuid, team_id: self.config['team_id'].to_i, language: language).last
      unless resource.nil?
        message = resource.format_as_tipline_message.to_s
        if ['image', 'audio', 'video'].include?(resource.header_type)
          type = resource.header_type
          type = 'video' if type == 'audio' # Audio gets converted to video with a cover
          type = 'file' if type == 'video' && RequestStore.store[:smooch_bot_provider] == 'ZENDESK' # Smooch doesn't support video
          self.send_message_to_user(uid, message, { 'type' => type, 'mediaUrl' => CheckS3.rewrite_url(resource.header_media_url) }, false, true, 'resource')
          sleep 3 # Wait a few seconds before sending the main menu
          self.send_message_for_state(uid, workflow, 'main', language)
        else
          preview_url = (resource.header_type == 'link_preview')
          self.send_final_messages_to_user(uid, message, workflow, language, 1, preview_url, 'resource') unless message.blank?
        end
      end
      resource
    end
  end
end
