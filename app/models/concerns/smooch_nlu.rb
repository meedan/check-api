require 'active_support/concern'

module SmoochNlu
  extend ActiveSupport::Concern

  module ClassMethods
    # FIXME: Refactor the rest of the Smooch-related code to use this helper
    def get_smooch_bot_installation_for_nlu(team_slug)
      TeamBotInstallation.where(team: Team.find_by_slug(team_slug), user: BotUser.smooch_user).last
    end

    def toggle_nlu(team_slug, enabled)
      tbi = self.get_smooch_bot_installation_for_nlu(team_slug)
      if tbi.nil?
        false
      else
        tbi.set_nlu_menus_enabled = enabled
        tbi.save!
        true
      end
    end

    def nlu_enabled?
      !!self.config.to_h['nlu_menus_enabled']
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

    # FIXME: Make it more flexible
    def nlu_models_to_use
      [Bot::Alegre::MEAN_TOKENS_MODEL]
    end

    # "menu" is "main" or "secondary"
    # "operation" is "add" or "remove"
    def update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword, operation)
      tbi = self.get_smooch_bot_installation_for_nlu(team_slug)
      alegre_operation = nil
      alegre_params = nil
      tbi.get_smooch_workflows.each do |workflow|
        if workflow['smooch_workflow_language'] == language
          keywords = workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'].to_a
          # Make sure there is a unique identifier for this menu option
          # FIXME: This whole thing should be a model :(
          menu_option_id = (workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_id'] ||= SecureRandom.uuid)
          if operation == 'add'
            keywords << keyword
            alegre_operation = 'post'
            alegre_params = self.common_nlu_params_for_alegre(team_slug, menu, menu_option_id, keyword).merge({ text: keyword, models: self.nlu_models_to_use })
          elsif operation == 'remove'
            keywords -= [keyword]
            alegre_operation = 'delete'
            alegre_params = self.common_nlu_params_for_alegre(team_slug, menu, menu_option_id, keyword).merge({ quiet: true })
          end
          workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'] = keywords
        end
      end
      tbi.save!
      # FIXME: Add error handling and better logging
      Bot::Alegre.request_api(alegre_operation, '/text/similarity/', alegre_params) if alegre_operation && alegre_params
    end

    def add_nlu_keyword(team_slug, language, menu, menu_option_index, keyword)
      self.update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword, 'add')
    end

    def remove_nlu_keyword(team_slug, language, menu, menu_option_index, keyword)
      self.update_nlu_keywords(team_slug, language, menu, menu_option_index, keyword, 'remove')
    end

    def nlu_menu_option_from_message(message, options)
      option = nil
      if self.nlu_enabled?
        # FIXME: No need to call Alegre if it's an exact match to one of the keywords
        # FIXME: No need to call Alegre if message is too short
        # FIXME: Handle error responses from Alegre
        response = Bot::Alegre.request_api('get', '/text/similarity/', { text: message, models: self.nlu_models_to_use, context: { context: 'smooch-nlu-menu', team: Team.find(self.config['team_id']).slug } })
        best_result = response['result'].to_a.sort_by{ |result| result['_score'] }.last
        unless best_result.nil?
          option = options.find{ |o| !o['smooch_menu_option_id'].blank? && o['smooch_menu_option_id'] == best_result.dig('_source', 'context', 'menu_option_id') }
        end
      end
      option
    end
  end
end
