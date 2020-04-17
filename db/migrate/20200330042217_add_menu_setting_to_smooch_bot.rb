class AddMenuSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone || []
      i = 19
      settings.insert(i, { name: 'smooch_message_smooch_bot_greetings', label: 'First message that is sent to the user as an introduction about the service', type: 'string', default: '' })
      {
        'main': 'Main menu',
        'secondary': 'Secondary menu',
        'query': 'User query'
      }.each do |state, label|
        i += 1
        settings.insert(i, {
          'name': "smooch_state_#{state}",
          'label': label,
          'type': 'object',
          'default': {},
          'properties': {
            'smooch_menu_message': {
              'type': 'string',
              'title': 'Message',
              'default': ''
            },
            'smooch_menu_options': {
              'title': 'Menu options',
              'type': 'array',
              'default': [],
              'items': {
                'title': 'Option',
                'type': 'object',
                'properties': {
                  'smooch_menu_option_keyword': {
                    'title': 'If',
                    'type': 'string',
                    'default': ''
                  },
                  'smooch_menu_option_value': {
                    'title': 'Then',
                    'type': 'string',
                    'enum': [
                      { 'key': 'main_state', 'value': 'Main menu' },
                      { 'key': 'secondary_state', 'value': 'Secondary menu' },
                      { 'key': 'query_state', 'value': 'User query' },
                      { 'key': 'resource', 'value': 'Report' }
                    ],
                    'default': ''
                  },
                  'smooch_menu_project_media_title': {
                    'title': 'Then',
                    'type': 'string',
                    'default': '',
                  },
                  'smooch_menu_project_media_id': {
                    'title': 'Project Media ID',
                    'type': ['string', 'integer'],
                    'default': '',
                  },
                }
              }
            }
          }
        })
      end
      settings.insert(i, { name: 'smooch_message_smooch_bot_option_not_available', label: 'Option not available', type: 'string', default: '' })
      tb.set_settings(settings)
      tb.save!
    end
  end
end
