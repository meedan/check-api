require 'sample_data'

class SmoochBotTestHelper
  extend SampleData

  SETTINGS = [
    {
      "name": "smooch_workflows",
      "label": "Workflows",
      "type": "array",
      "default": [
        {
          "smooch_workflow_language": "en"
        }
      ],
      "items": {
        "title": "Workflow",
        "type": "object",
        "properties": {
          "smooch_workflow_language": {
            "title": "Language",
            "type": "string",
            "default": "en"
          },
          "smooch_message_smooch_bot_result_changed": {
            "type": "string",
            "title": "Message sent with the new verification results when a final status of an item changes (placeholders: %{previous_status} (previous final status of the report), %{status} (new final status of the report) and %{url} (public URL to verification results))",
            "default": ""
          },
          "smooch_message_smooch_bot_message_confirmed": {
            "type": "string",
            "title": "Message that confirms to the user that the request is in the queue to be verified",
            "default": ""
          },
          "smooch_message_smooch_bot_message_type_unsupported": {
            "type": "string",
            "title": "Message that informs the user that the type of message is not supported (for example, audio and video)",
            "default": ""
          },
          "smooch_message_smooch_bot_disabled": {
            "type": "string",
            "title": "Message sent to user when this bot is disabled and not accepting requests",
            "default": ""
          },
          "smooch_message_smooch_bot_tos": {
            "type": "object",
            "title": "Privacy statement",
            "properties": {
              "greeting": {
                "type": "string",
                "default": ""
              },
              "content": {
                "type": "string",
                "default": ""
              }
            }
          },
          "smooch_message_smooch_bot_greetings": {
            "type": "string",
            "title": "First message that is sent to the user as an introduction about the service",
            "default": ""
          },
          "smooch_state_subscription": {
            "type": "object",
            "title": "Subscription opt-in",
            "properties": {
              "smooch_menu_message": {
                "type": "string",
                "title": "Message",
                "default": ""
              },
              "smooch_menu_options": {
                "title": "Menu options",
                "type": "array",
                "default": [],
                "items": {
                  "title": "Option",
                  "type": "object",
                  "properties": {
                    "smooch_menu_option_keyword": {
                      "title": "If",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_option_value": {
                      "title": "Then",
                      "type": "string",
                      "enum": [
                        {
                          "key": "main_state",
                          "value": "Main menu"
                        },
                        {
                          "key": "subscription_confirmation",
                          "value": "Subscription confirmation"
                        },
                      ],
                      "default": ""
                    },
                  }
                }
              }
            }
          },
          "smooch_state_main": {
            "type": "object",
            "title": "Main menu",
            "properties": {
              "smooch_menu_message": {
                "type": "string",
                "title": "Message",
                "default": ""
              },
              "smooch_menu_options": {
                "title": "Menu options",
                "type": "array",
                "default": [],
                "items": {
                  "title": "Option",
                  "type": "object",
                  "properties": {
                    "smooch_menu_option_keyword": {
                      "title": "If",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_option_value": {
                      "title": "Then",
                      "type": "string",
                      "enum": [
                        {
                          "key": "main_state",
                          "value": "Main menu"
                        },
                        {
                          "key": "secondary_state",
                          "value": "Secondary menu"
                        },
                        {
                          "key": "query_state",
                          "value": "Query prompt"
                        },
                        {
                          "key": "resource",
                          "value": "Report"
                        },
                        {
                          "key": "custom_resource",
                          "value": "Custom resource"
                        },
                        {
                          "key": "subscription_state",
                          "value": "Subscription opt-in"
                        }
                      ],
                      "default": ""
                    },
                    "smooch_menu_project_media_title": {
                      "title": "Then",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_project_media_id": {
                      "title": "Project Media ID",
                      "type": [
                        "string",
                        "integer"
                      ],
                      "default": ""
                    },
                    "smooch_menu_custom_resource_id": {
                      "title": "Custom resource ID",
                      "type": "string",
                      "default": ""
                    }
                  }
                }
              }
            }
          },
          "smooch_state_secondary": {
            "type": "object",
            "title": "Secondary menu",
            "properties": {
              "smooch_menu_message": {
                "type": "string",
                "title": "Message",
                "default": ""
              },
              "smooch_menu_options": {
                "title": "Menu options",
                "type": "array",
                "default": [],
                "items": {
                  "title": "Option",
                  "type": "object",
                  "properties": {
                    "smooch_menu_option_keyword": {
                      "title": "If",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_option_value": {
                      "title": "Then",
                      "type": "string",
                      "enum": [
                        {
                          "key": "main_state",
                          "value": "Main menu"
                        },
                        {
                          "key": "secondary_state",
                          "value": "Secondary menu"
                        },
                        {
                          "key": "query_state",
                          "value": "Query prompt"
                        },
                        {
                          "key": "resource",
                          "value": "Report"
                        },
                        {
                          "key": "custom_resource",
                          "value": "Custom resource"
                        },
                        {
                          "key": "subscription_state",
                          "value": "Subscription opt-in"
                        }
                      ],
                      "default": ""
                    },
                    "smooch_menu_project_media_title": {
                      "title": "Then",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_project_media_id": {
                      "title": "Project Media ID",
                      "type": [
                        "string",
                        "integer"
                      ],
                      "default": ""
                    },
                    "smooch_menu_custom_resource_id": {
                      "title": "Custom resource ID",
                      "type": "string",
                      "default": ""
                    }
                  }
                }
              }
            }
          },
          "smooch_message_smooch_bot_option_not_available": {
            "type": "string",
            "title": "Option not available",
            "default": ""
          },
          "smooch_custom_resources": {
            type: 'array',
            title: 'Custom Resources',
            items: {
              type: 'object',
              properties: {
                smooch_custom_resource_id: {
                  type: 'string',
                  title: 'ID',
                  default: '',
                },
                smooch_custom_resource_title: {
                  type: 'string',
                  title: 'Title',
                  default: '',
                },
                smooch_custom_resource_body: {
                  type: 'string',
                  title: 'Body',
                  default: '',
                },
                smooch_custom_resource_feed_url: {
                  type: 'string',
                  title: 'Feed URL',
                  default: '',
                },
                smooch_custom_resource_number_of_articles: {
                  type: 'integer',
                  title: 'Number of articles',
                  default: 3,
                }
              }
            }
          },
          "smooch_state_query": {
            "type": "object",
            "title": "User query",
            "properties": {
              "smooch_menu_message": {
                "type": "string",
                "title": "Message",
                "default": ""
              },
              "smooch_menu_options": {
                "title": "Menu options",
                "type": "array",
                "default": [],
                "items": {
                  "title": "Option",
                  "type": "object",
                  "properties": {
                    "smooch_menu_option_keyword": {
                      "title": "If",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_option_value": {
                      "title": "Then",
                      "type": "string",
                      "enum": [
                        {
                          "key": "main_state",
                          "value": "Main menu"
                        },
                        {
                          "key": "secondary_state",
                          "value": "Secondary menu"
                        },
                        {
                          "key": "query_state",
                          "value": "Query prompt"
                        },
                        {
                          "key": "resource",
                          "value": "Report"
                        },
                        {
                          "key": "custom_resource",
                          "value": "Custom resource"
                        },
                        {
                          "key": "subscription_state",
                          "value": "Subscription opt-in"
                        }
                      ],
                      "default": ""
                    },
                    "smooch_menu_project_media_title": {
                      "title": "Then",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_custom_resource_id": {
                      "title": "Custom resource ID",
                      "type": "string",
                      "default": ""
                    },
                    "smooch_menu_project_media_id": {
                      "title": "Project Media ID",
                      "type": [
                        "string",
                        "integer"
                      ],
                      "default": ""
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    {
      "name": "smooch_app_id",
      "label": "Smooch App ID",
      "type": "string",
      "default": ""
    },
    {
      "name": "smooch_secret_key_key_id",
      "label": "Smooch Secret Key: Key ID",
      "type": "string",
      "default": ""
    },
    {
      "name": "smooch_secret_key_secret",
      "label": "Smooch Secret Key: Secret",
      "type": "string",
      "default": ""
    },
    {
      "name": "smooch_webhook_secret",
      "label": "Smooch Webhook Secret",
      "type": "string",
      "default": ""
    },
    {
      "name": "smooch_template_namespace",
      "label": "Smooch Template Namespace",
      "type": "string",
      "default": ""
    },
    {
      "name": "smooch_twitter_authorization_url",
      "label": "Visit this link to authorize the Twitter Business Account that will forward DMs to this bot",
      "type": "readonly",
      "default": ""
    },
    {
      "name": "smooch_disabled",
      "label": "Disable",
      "type": "boolean",
      "default": "false"
    },
    {
      "name": "smooch_authorization_token",
      "label": "Internal Token (used for authorization)",
      "type": "hidden",
      "default": ""
    },
    {
      "name": "smooch_template_locales",
      "label": "Choose which locales are supported by the templates",
      "type": "array",
      "default": [
        "en"
      ],
      "items": {
        "type": "string",
        "enum": [
          "en"
        ]
      }
    }
  ]

  DEFAULT_SMOOCH_WORKFLOW_LANGUAGE = {
      'smooch_workflow_language' => 'en',
      'smooch_message_smooch_bot_greetings' => 'Hello!',
      'smooch_message_smooch_bot_tos' => {
        'greeting' => 'Send 9 to read the terms of service.',
        'content' => 'Custom terms of service.'
      }
    }

  SECOND_SMOOCH_WORKFLOW_LANGUAGE = {
      'smooch_workflow_language' => 'pt',
      'smooch_state_main' => {
        'smooch_menu_message' => 'Olá, bem-vindo! Envie 1 para enviar uma requisição.',
        'smooch_menu_options' => [{
          'smooch_menu_option_keyword' => '1, um',
          'smooch_menu_option_value' => 'query_state',
          'smooch_menu_project_media_id' => ''
        }]
      },
      'smooch_state_query' => {
        'smooch_menu_message' => 'Enter your query or send 0 to go back to the main menu',
        'smooch_menu_options' => []
      }
    }

  def self.smooch_basic_settings(app_id, team_id)
    {
      'smooch_webhook_secret' => 'test',
      'smooch_app_id' => app_id,
      'smooch_secret_key_key_id' => random_string,
      'smooch_secret_key_secret' => random_string,
      'smooch_template_namespace' => random_string,
      'team_id' => team_id,
      'smooch_workflows' => [ DEFAULT_SMOOCH_WORKFLOW_LANGUAGE ]
    }
  end

  def self.smooch_menu_custom_settings(pm_for_menu_option_id, resource_uuid)
    {
      'smooch_state_main' => {
        'smooch_menu_message' => 'Hello, welcome! Press 1 to go to secondary menu.',
        'smooch_menu_options' => [
          {
            'smooch_menu_option_keyword' => '1 ,one',
            'smooch_menu_option_value' => 'secondary_state',
            'smooch_menu_project_media_id' => ''
          },
          {
            'smooch_menu_option_keyword' => 'query',
            'smooch_menu_option_value' => 'query_state',
          },
          {
            'smooch_menu_option_keyword' => 'newsletter',
            'smooch_menu_option_value' => 'subscription_state',
          }
        ]
      },
      'smooch_state_secondary' => {
        'smooch_menu_message' => 'Now press 1 to see a project media or 2 to go to the query menu',
        'smooch_menu_options' => [
          {
            'smooch_menu_option_keyword' => ' 1, one',
            'smooch_menu_option_value' => 'resource',
            'smooch_menu_project_media_id' => pm_for_menu_option_id
          },
          {
            'smooch_menu_option_keyword' => '2, two ',
            'smooch_menu_option_value' => 'query_state',
            'smooch_menu_project_media_id' => ''
          },
          {
            'smooch_menu_option_keyword' => ' 3 , three ',
            'smooch_menu_option_value' => 'pt',
            'smooch_menu_project_media_id' => ''
          },
          {
            'smooch_menu_option_keyword' => '4',
            'smooch_menu_option_value' => 'custom_resource',
            'smooch_menu_custom_resource_id' => resource_uuid
          },
          {
            'smooch_menu_option_keyword' => '5',
            'smooch_menu_option_value' => 'subscription_state',
          }
        ]
      },
      'smooch_state_subscription' => {
        'smooch_menu_message' => 'Enter your query or send 0 to go back to the main menu',
        'smooch_menu_options' => [
          {
            'smooch_menu_option_keyword' => '0',
            'smooch_menu_option_value' => 'main_state',
          },
          {
            'smooch_menu_option_keyword' => '1',
            'smooch_menu_option_value' => 'subscription_confirmation',
          }
        ]
      },
      'smooch_state_query' => {
        'smooch_menu_message' => 'Enter your query or send 0 to go back to the main menu',
        'smooch_menu_options' => [
          {
            'smooch_menu_option_keyword' => '0,zero',
            'smooch_menu_option_value' => 'main_state',
            'smooch_menu_project_media_id' => ''
          }
        ]
      },
      'smooch_custom_resources' => [
        {
          'smooch_custom_resource_id' => resource_uuid,
          'smooch_custom_resource_title' => 'Latest articles',
          'smooch_custom_resource_body' => 'Take a look at our latest published articles.',
          'smooch_custom_resource_feed_url' => 'http://test.com/feed.rss',
          'smooch_custom_resource_number_of_articles' => 3,
        }
      ]
    }
  end

  def self.smooch_menu_default_language(smooch_menu, settings)
    settings['smooch_workflows'][0].merge!(smooch_menu)
  end

  def self.smooch_menu_second_language(settings)
    settings['smooch_workflows'][1] = settings['smooch_workflows'][0].deep_dup.merge(SmoochBotTestHelper::SECOND_SMOOCH_WORKFLOW_LANGUAGE)
  end
end
