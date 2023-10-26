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
    def menu_option_from_message(message, language, options)
      return nil if options.blank?
      option = nil
      context = {
        context: ALEGRE_CONTEXT_KEY_MENU
      }
      matches = SmoochNlu.alegre_matches_from_message(message, language, context, 'menu_option_id')
      # Select the top menu option that exists in `options`
      matches.each do |r|
        option = options.find{ |o| !o['smooch_menu_option_id'].blank? && o['smooch_menu_option_id'] == r }
        break unless option.nil?
      end
      Rails.logger.info("[Smooch NLU] [Menu Option From Message] Menu option: #{option} | Message: #{message}")
      option
    end
  end
end
