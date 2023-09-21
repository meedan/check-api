class SmoochNlu
  class SmoochBotNotInstalledError < ::ArgumentError
  end

  # FIXME: Make it more flexible
  # FIXME: Once we support paraphrase-multilingual-mpnet-base-v2 make it the only model used
  ALEGRE_MODELS_AND_THRESHOLDS = {
    Bot::Alegre::OPENAI_ADA_MODEL => 0.8,
    Bot::Alegre::MEAN_TOKENS_MODEL => 0.6
  }

  ALEGRE_CONTEXT_KEY = {
    menu: 'smooch_nlu_menu',
    resource: 'smooch_nlu_resource'
  }

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
    !!@smooch_bot_installation.get_nlu_enabled
  end

  def add_keyword_to_menu_option(language, menu, menu_option_index, keyword)
    update_menu_option_keywords(language, menu, menu_option_index, keyword, 'add')
  end

  def remove_keyword_from_menu_option(language, menu, menu_option_index, keyword)
    update_menu_option_keywords(language, menu, menu_option_index, keyword, 'remove')
  end

  def list_menu_keywords(languages = nil, menus = nil)
    if languages.nil?
      languages = @smooch_bot_installation.get_smooch_workflows.map { |w| w['smooch_workflow_language'] }
    elsif languages.is_a? String
      languages = [languages]
    end
    if menus.nil?
      menus = ['main', 'secondary']
    elsif menus.is_a? String
      menus = [menus]
    end

    output = {}
    languages.each do |language|
      output[language] = {}
      workflow = @smooch_bot_installation.get_smooch_workflows.find { |w| w['smooch_workflow_language'] == language }
      menus.each do |menu|
        output[language][menu] = []
        i = 0
        workflow.fetch("smooch_state_#{menu}",{}).fetch('smooch_menu_options', []).each do |option|
          output[language][menu] << {
            'index' => i,
            'title' => option.dig('smooch_menu_option_label'),
            'keywords' => option.dig('smooch_menu_option_nlu_keywords').to_a,
            'id' => option.dig('smooch_menu_option_id'),
          }
          i += 1
        end
      end
    end
    output
  end

  def self.menu_option_from_message(message, language, options)
    # FIXME: Raise exception if not in a tipline context (so, if Bot::Smooch.config is nil)
    option = nil
    team_slug = Team.find(Bot::Smooch.config['team_id']).slug
    params = nil
    response = nil
    if Bot::Smooch.config.to_h['nlu_enabled'] && !options.nil?
      # FIXME: In the future we could consider menus across all languages when options is nil
      # FIXME: No need to call Alegre if it's an exact match to one of the keywords
      # FIXME: No need to call Alegre if message has no word characters
      # FIXME: Handle error responses from Alegre
      params = {
        text: message,
        models: ALEGRE_MODELS_AND_THRESHOLDS.keys,
        per_model_threshold: ALEGRE_MODELS_AND_THRESHOLDS,
        context: {
          context: ALEGRE_CONTEXT_KEY[:menu],
          team: team_slug,
          language: language,
        }
      }
      response = Bot::Alegre.request_api('get', '/text/similarity/', params)

      # One approach would be to take the option that has the most matches
      # Unfortunately this approach is influenced by the number of keywords per option
      # So, we are not using this approach right now
      # Get the menu_option_id of all results returned
      # option_counts = response['result'].to_a.map{|o| o.dig('_source', 'context', 'menu_option_id')}
      # Count how many of each menu_option_id we have and sort (high to low)
      # ranked_options = option_counts.group_by(&:itself).transform_values(&:count).sort_by{|_k,v| v}.reverse()

      # Second approach is to sort the results from best to worst
      sorted_options = response['result'].to_a.sort_by{ |result| result['_score'] }.reverse()
      ranked_options = sorted_options.map{|o| o.dig('_source', 'context', 'menu_option_id')}

      # Select the top menu option that exists in `options`
      ranked_options.each do | r |
        option = options.find{ |o| !o['smooch_menu_option_id'].blank? && o['smooch_menu_option_id'] == r }
        break if !option.nil?
      end

      # FIXME: Deal with ties (i.e., where two options have an equal _score or count)
    end
    # In all cases log for analysis
    log = {
      version: "0.1", # Update if schema changes
      datetime: DateTime.current,
      team_slug: team_slug,
      user_query: message,
      alegre_query: params,
      alegre_response: response,
      selected_option: option
    }
    Rails.logger.info("[Smooch NLU] [Menu Option From Message] #{log.to_json}")
    option
  end

  private

  def toggle!(enabled)
    @smooch_bot_installation.set_nlu_enabled = enabled
    @smooch_bot_installation.save!
    @smooch_bot_installation.reload
  end

  # "menu" is "main" or "secondary"
  # "operation" is "add" or "remove"
  # FIXME: Validate the two things above
  def update_menu_option_keywords(language, menu, menu_option_index, keyword, operation)
    alegre_operation = nil
    alegre_params = nil
    workflow = @smooch_bot_installation.get_smooch_workflows.find { |w| w['smooch_workflow_language'] == language }
    keywords = workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'].to_a
    # Make sure there is a unique identifier for this menu option
    # FIXME: This whole thing should be a model :(
    menu_option_id = (workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_id'] ||= SecureRandom.uuid)
    doc_id = Digest::MD5.hexdigest([ALEGRE_CONTEXT_KEY[:menu], @team_slug, menu, menu_option_id, keyword].join(':'))
    common_alegre_params = {
      doc_id: doc_id,
      context: {
        context: ALEGRE_CONTEXT_KEY[:menu],
        team: @team_slug,
        language: language,
        menu: menu,
        menu_option_id: menu_option_id
      }
    }
    if operation == 'add' && !keywords.include?(keyword)
      keywords << keyword
      alegre_operation = 'post'
      alegre_params = common_alegre_params.merge({ text: keyword, models: ALEGRE_MODELS_AND_THRESHOLDS.keys })
    elsif operation == 'remove'
      keywords -= [keyword]
      alegre_operation = 'delete'
      alegre_params = common_alegre_params.merge({ quiet: true })
    end
    workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'] = keywords
    @smooch_bot_installation.save!
    @smooch_bot_installation.reload
    # FIXME: Add error handling and better logging
    Bot::Alegre.request_api(alegre_operation, '/text/similarity/', alegre_params) if alegre_operation && alegre_params
  end
end
