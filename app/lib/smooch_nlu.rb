class SmoochNlu
  class SmoochBotNotInstalledError < ::ArgumentError
  end

  # FIXME: Make it more flexible
  # FIXME: Once we support paraphrase-multilingual-mpnet-base-v2 make it the only model used
  ALEGRE_MODELS_AND_THRESHOLDS = {
    Bot::Alegre::OPENAI_ADA_MODEL => 0.8,
    Bot::Alegre::MEAN_TOKENS_MODEL => 0.6
  }

  ALEGRE_CONTEXT_KEY = 'smooch_nlu_menu'

  def initialize(team_slug)
    @team_slug = team_slug
    @smooch_bot_installation = TeamBotInstallation.where(team: Team.find_by_slug(team_slug), user: BotUser.smooch_user).last
    raise SmoochBotNotInstalledError, "Smooch Bot not installed for workspace with slug #{team_slug}" if @smooch_bot_installation.nil?
  end

  def enable!
    toggle!(true)
  end

  def disable!
    toggle!(false)
  end

  def enabled?
    !!@smooch_bot_installation.get_nlu_menus_enabled
  end

  def add_keyword(language, menu, menu_option_index, keyword)
    update_keywords(language, menu, menu_option_index, keyword, 'add')
  end

  def remove_keyword(language, menu, menu_option_index, keyword)
    update_keywords(language, menu, menu_option_index, keyword, 'remove')
  end

  def self.menu_option_from_message(message, options)
    # FIXME: Raise exception if not in a tipline context (so, if Bot::Smooch.config is nil)
    option = nil
    if Bot::Smooch.config.to_h['nlu_menus_enabled']
      # FIXME: No need to call Alegre if it's an exact match to one of the keywords
      # FIXME: No need to call Alegre if message has no word characters
      # FIXME: Handle error responses from Alegre
      params = {
        text: message,
        models: ALEGRE_MODELS_AND_THRESHOLDS.keys,
        per_model_threshold: ALEGRE_MODELS_AND_THRESHOLDS,
        context: {
          context: ALEGRE_CONTEXT_KEY,
          team: Team.find(Bot::Smooch.config['team_id']).slug
        }
      }
      response = Bot::Alegre.request_api('get', '/text/similarity/', params)
      best_result = response['result'].to_a.sort_by{ |result| result['_score'] }.last
      unless best_result.nil?
        option = options.find{ |o| !o['smooch_menu_option_id'].blank? && o['smooch_menu_option_id'] == best_result.dig('_source', 'context', 'menu_option_id') }
      end
    end
    option
  end

  private

  def toggle!(enabled)
    @smooch_bot_installation.set_nlu_menus_enabled = enabled
    @smooch_bot_installation.save!
    @smooch_bot_installation.reload
  end

  def alegre_doc_id(menu, menu_option_id, keyword)
    Digest::MD5.hexdigest([ALEGRE_CONTEXT_KEY, @team_slug, menu, menu_option_id, keyword].join(':'))
  end

  def common_params_for_alegre(menu, menu_option_id, keyword)
    {
      doc_id: alegre_doc_id(menu, menu_option_id, keyword),
      context: {
        context: ALEGRE_CONTEXT_KEY,
        team: @team_slug,
        menu: menu,
        menu_option_id: menu_option_id
      }
    }
  end

  # "menu" is "main" or "secondary"
  # "operation" is "add" or "remove"
  # FIXME: Validate the two things above
  def update_keywords(language, menu, menu_option_index, keyword, operation)
    alegre_operation = nil
    alegre_params = nil
    workflow = @smooch_bot_installation.get_smooch_workflows.find { |w| w['smooch_workflow_language'] == language }
    keywords = workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'].to_a
    # Make sure there is a unique identifier for this menu option
    # FIXME: This whole thing should be a model :(
    menu_option_id = (workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_id'] ||= SecureRandom.uuid)
    if operation == 'add' && !keywords.include?(keyword)
      keywords << keyword
      alegre_operation = 'post'
      alegre_params = common_params_for_alegre(menu, menu_option_id, keyword).merge({ text: keyword, models: ALEGRE_MODELS_AND_THRESHOLDS.keys })
    elsif operation == 'remove'
      keywords -= [keyword]
      alegre_operation = 'delete'
      alegre_params = common_params_for_alegre(menu, menu_option_id, keyword).merge({ quiet: true })
    end
    workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'] = keywords
    @smooch_bot_installation.save!
    @smooch_bot_installation.reload
    # FIXME: Add error handling and better logging
    Bot::Alegre.request_api(alegre_operation, '/text/similarity/', alegre_params) if alegre_operation && alegre_params
  end
end
