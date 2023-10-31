module SmoochNluMenus
  ALEGRE_CONTEXT_KEY_MENU = 'smooch_nlu_menu'

  def self.included(base)
    base.extend(ClassMethods)
  end

  def add_keyword_to_menu_option(language, menu, menu_option_index, keyword)
    update_menu_option_keywords(language, menu, menu_option_index, keyword, 'add')
  end

  def remove_keyword_from_menu_option(language, menu, menu_option_index, keyword)
    update_menu_option_keywords(language, menu, menu_option_index, keyword, 'remove')
  end

  def list_menu_keywords(languages = nil, menus = nil, include_empty = true)
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
          keywords = option.dig('smooch_menu_option_nlu_keywords').to_a
          output[language][menu] << {
            'index' => i,
            'title' => option.dig('smooch_menu_option_label'),
            'keywords' => keywords,
            'id' => option.dig('smooch_menu_option_id'),
          } if include_empty || !keywords.blank?
          i += 1
        end
      end
    end
    output
  end

  # "menu" is "main" or "secondary"
  # "operation" is "add" or "remove"
  # FIXME: Validate the two things above
  def update_menu_option_keywords(language, menu, menu_option_index, keyword, operation)
    workflow = @smooch_bot_installation.get_smooch_workflows.find { |w| w['smooch_workflow_language'] == language }
    keywords = workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'].to_a
    menu_option_id = (workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_id'] ||= SecureRandom.uuid)
    doc_id = Digest::MD5.hexdigest([ALEGRE_CONTEXT_KEY_MENU, @team_slug, menu, menu_option_id, keyword].join(':'))
    context = {
      context: ALEGRE_CONTEXT_KEY_MENU,
      menu: menu,
      menu_option_id: menu_option_id
    }
    new_keywords = update_keywords(language, keywords, keyword, operation, doc_id, context)
    workflow["smooch_state_#{menu}"]['smooch_menu_options'][menu_option_index]['smooch_menu_option_nlu_keywords'] = new_keywords
    @smooch_bot_installation.save!
    @smooch_bot_installation.reload
  end

  module ClassMethods
    def menu_options_from_message(message, language, options)
      return [{ 'smooch_menu_option_value' => 'main_state' }] if message == 'cancel_nlu'
      return [] if options.blank?
      context = {
        context: ALEGRE_CONTEXT_KEY_MENU
      }
      matches = SmoochNlu.alegre_matches_from_message(message, language, context, 'menu_option_id')
      # Select the top two menu options that exists in `options`
      top_options = []
      matches.each do |r|
        option = options.find { |o| !o['smooch_menu_option_id'].blank? && o['smooch_menu_option_id'] == r['key'] }
        top_options << { 'option' => option, 'score' => r['score'] } if !option.nil? && (top_options.empty? || (top_options.first['score'] - r['score']) <= SmoochNlu.disambiguation_threshold)
        break if top_options.size == 2
      end
      Rails.logger.info("[Smooch NLU] [Menu Option From Message] Menu options: #{top_options.inspect} | Message: #{message}")
      top_options.collect{ |o| o['option'] }
    end

    def process_menu_options(uid, options, message, language, workflow, app_id)

      if options.size == 1
        Bot::Smooch.process_menu_option_value(options.first['smooch_menu_option_value'], options.first, message, language, workflow, app_id)
      # Disambiguation
      else
        buttons = options.collect do |option|
          {
            value: { keyword: option['smooch_menu_option_keyword'] }.to_json,
            label: option['smooch_menu_option_label']
          }
        end.concat([{ value: { keyword: 'cancel_nlu' }.to_json, label: Bot::Smooch.get_string('nlu_cancel', language, 20) }])
        Bot::Smooch.send_message_to_user_with_buttons(uid, Bot::Smooch.get_string('nlu_disambiguation', language), buttons)
      end
    end
  end
end
