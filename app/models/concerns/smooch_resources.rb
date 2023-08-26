require 'active_support/concern'

module SmoochResources
  extend ActiveSupport::Concern

  module ClassMethods
    # This is the method called by the Smooch Bot
    def send_resource_to_user(uid, workflow, option, language)
      resource = TiplineResource.where(uuid: option['smooch_menu_custom_resource_id'].to_s, team_id: self.config['team_id'].to_i, language: language).last
      unless resource.nil?
        message = resource.format_as_tipline_message
        self.send_final_messages_to_user(uid, message, workflow, language) unless message.blank?
      end
      resource
    end
  end
end
