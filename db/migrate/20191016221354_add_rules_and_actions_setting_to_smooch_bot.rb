class AddRulesAndActionsSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << {
        "name": "smooch_rules_and_actions",
        "label": "Rules and Actions",
        "type": "array",
        "items": {
          "title": "Rules and Actions",
          "type": "object",
          "properties": {
            "smooch_rules": {
              "title": "Rules",
              "type": "array",
              "items": {
                "title": "Rule",
                "type": "object",
                "properties": {
                  "smooch_rule_definition": {
                    "title": "Rule Definition",
                    "type": "string",
                    "enum": [
                      { "key": "has_less_than_x_words", "value": "Message has less than this number of words" },
                      { "key": "matches_regexp", "value": "Message matches this regular expression" },
                      { "key": "contains_keyword", "value": "Message contains at least one of the following keywords (separated by commas)" }
                    ]
                  },
                  "smooch_rule_value": {
                    "title": "Value",
                    "type": "string"
                  }
                }
              }
            },
            "smooch_actions": {
              "title": "Actions",
              "type": "array",
              "items": {
                "title": "Action",
                "type": "object",
                "properties": {
                  "smooch_action_definition": {
                    "title": "Action Definition",
                    "type": "string",
                    "enum": [
                      { "key": "send_to_trash", "value": "Send to trash" },
                      { "key": "move_to_project", "value": "Move to project (please provide project ID)" },
                      { "key": "ban_submitter", "value": "Ban submitting user" }
                    ]
                  },
                  "smooch_action_value": {
                    "title": "Value",
                    "type": "string"
                  }
                }
              }
            }
          }
        }
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
