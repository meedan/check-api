require 'active_support/concern'

module SmoochNlu
  extend ActiveSupport::Concern

  module ClassMethods
    def get_smooch_bot_installation_for_nlu(team_slug)
      TeamBotInstallation.where(team: Team.find_by_slug(team_slug), user: BotUser.smooch_user).last
    end

    def toggle_nlu(team_slug, enabled)
      tbi = self.get_team_bot_installation_for_nlu(team_slug) 
      if tbi.nil?
        false
      else
        tbi.set_nlu_menus_enabled = enabled
        tbi.save!
        true
      end
    end

    def enable_nlu(team_slug)
      self.toggle_nlu(team_slug, true)
    end

    def disable_nlu(team_slug)
      self.toggle_nlu(team_slug, false)
    end

    # "menu" is "main" or "secondary"
    # "operation" is "add" or "remove"
    def update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword, operation)
      tbi = self.get_team_bot_installation_for_nlu(team_slug) 
      self.get_smooch_workflows.each do |workflow|
        if workflow['smooch_workflow_language'] == language
          keywords = workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'].to_a
          if operation == 'add'
            keywords << keyword
          elsif operation == 'remove'
            keywords -= [eyword]
          end
          workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'] = keywords
        end
      end
      tbi.save!
    end

    def add_nlu_keyword(team_slug, language, menu, menu_option_index, keyword)
      self.update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword , 'add')
    end

    def remove_nlu_keyword(team_slug, language, menu, menu_option_index, keyword)
      self.update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword , 'remove')
    end
  end
end
