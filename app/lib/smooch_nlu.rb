class SmoochNlu
  class SmoochBotNotInstalledError < ::ArgumentError
  end

  # FIXME: Make it more flexible
  # FIXME: Once we support paraphrase-multilingual-mpnet-base-v2 make it the only model used
  ALEGRE_MODELS_AND_THRESHOLDS = {
    # Bot::Alegre::ELASTICSEARCH_MODEL => 0.8 # Sometimes this is easier for local development
    # Bot::Alegre::OPENAI_ADA_MODEL => 0.8 # Not in use right now
    Bot::Alegre::PARAPHRASE_MULTILINGUAL_MODEL => 0.6
  }

  include SmoochNluMenus

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

  def update_keywords(language, keywords, keyword, operation, doc_id, context)
    alegre_operation = nil
    alegre_params = nil
    common_alegre_params = {
      doc_id: doc_id,
      context: {
        team: @team_slug,
        language: language
      }.merge(context)
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
    # FIXME: Add error handling and better logging
    Bot::Alegre.request_api(alegre_operation, '/text/similarity/', alegre_params) if alegre_operation && alegre_params
    keywords
  end

  # If NLU matches two results that have at least this distance between them, they are both presented to the user for disambiguation
  def self.disambiguation_threshold
    CheckConfig.get('nlu_disambiguation_threshold', 0.11, :float).to_f
  end

  def self.alegre_matches_from_message(message, language, context, alegre_result_key)
    # FIXME: Raise exception if not in a tipline context (so, if Bot::Smooch.config is nil)
    matches = []
    team_slug = Team.find(Bot::Smooch.config['team_id']).slug
    params = nil
    response = nil
    if Bot::Smooch.config.to_h['nlu_enabled']
      # FIXME: In the future we could consider matches across all languages when options is nil
      # FIXME: No need to call Alegre if it's an exact match to one of the keywords
      # FIXME: No need to call Alegre if message has no word characters
      # FIXME: Handle error responses from Alegre
      params = {
        text: message,
        models: SmoochNlu::ALEGRE_MODELS_AND_THRESHOLDS.keys,
        per_model_threshold: SmoochNlu::ALEGRE_MODELS_AND_THRESHOLDS,
        context: {
          team: team_slug,
          language: language,
        }.merge(context)
      }
      response = Bot::Alegre.request_api('get', '/text/similarity/', params)

      # One approach would be to take the option that has the most matches
      # Unfortunately this approach is influenced by the number of keywords per option
      # So, we are not using this approach right now
      # Get the `alegre_result_key` of all results returned
      # option_counts = response['result'].to_a.map{|o| o.dig('_source', 'context', alegre_result_key)}
      # Count how many of each alegre_result_key we have and sort (high to low)
      # ranked_options = option_counts.group_by(&:itself).transform_values(&:count).sort_by{|_k,v| v}.reverse()

      # Second approach is to sort the results from best to worst
      sorted_options = response['result'].to_a.sort_by{ |result| result['_score'] }.reverse
      ranked_options = sorted_options.map{ |o| { 'key' => o.dig('_source', 'context', alegre_result_key), 'score' => o['_score'] } }
      matches = ranked_options

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
      matches: matches
    }
    Rails.logger.info("[Smooch NLU] [Matches From Message] #{log.to_json}")
    matches
  end

  private

  def toggle!(enabled)
    @smooch_bot_installation.set_nlu_enabled = enabled
    @smooch_bot_installation.save!
    @smooch_bot_installation.reload
  end
end
