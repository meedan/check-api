require 'active_support/concern'

module SmoochNlu
  extend ActiveSupport::Concern

  module ClassMethods
    # FIXME: Refactor the rest of the Smooch-related code to use this helper
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

    def nlu_alegre_id(team_slug, menu, menu_option_id, keyword)
      Digest::MD5.hexdigest(['smooch-nlu-menu', team_slug, menu, menu_option_id, keyword].join(':'))
    end

    def common_nlu_params_for_alegre(team_slug, menu, menu_option_id, keyword)
      {
        doc_id: self.nlu_alegre_id(team_slug, menu, menu_option_id, keyword),
        context: {
          context: 'smooch-nlu-menu',
          team: team_slug,
          menu: menu,
          menu_option_id: menu_option_id
        }
      }
    end

    # "menu" is "main" or "secondary"
    # "operation" is "add" or "remove"
    def update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword, operation)
      tbi = self.get_team_bot_installation_for_nlu(team_slug)
      alegre_operation = nil
      alegre_params = nil
      self.get_smooch_workflows.each do |workflow|
        if workflow['smooch_workflow_language'] == language
          keywords = workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'].to_a
          # Make sure there is a unique identifier for this menu option
          # FIXME: This whole thing should be a model :(
          menu_option_id = (workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_id'] ||= SecureRandom.uuid)
          if operation == 'add'
            keywords << keyword
            alegre_operation = 'post'
            alegre_params = self.common_nlu_params_for_alegre(team_slug, menu, menu_option_id, keyword).merge({ text: keyword, models: [Bot::Alegre::MEAN_TOKENS_MODEL] })
          elsif operation == 'remove'
            keywords -= [keyword]
            alegre_operation = 'delete'
            alegre_params = self.common_nlu_params_for_alegre(team_slug, menu, menu_option_id, keyword).merge({ quiet: true })
          end
          workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'] = keywords
        end
      end
      tbi.save!
      Bot::Alegre.request_api(alegre_operation, '/text/similarity/', self.nlu_params_for_alegre(keyword)) if alegre_operation && alegre_params
    end

    def add_nlu_keyword(team_slug, language, menu, menu_option_index, keyword)
      self.update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword, 'add')
    end

    def remove_nlu_keyword(team_slug, language, menu, menu_option_index, keyword)
      self.update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword, 'remove')
    end
  end
end
