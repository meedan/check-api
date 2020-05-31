require Rails.root.join('lib', 'rails_admin', 'send_reset_password_email.rb')
require Rails.root.join('lib', 'rails_admin', 'export_project.rb')
require Rails.root.join('lib', 'rails_admin', 'export_images.rb')
require Rails.root.join('lib', 'rails_admin', 'yaml_field.rb')
require Rails.root.join('lib', 'rails_admin', 'dashboard.rb')
require Rails.root.join('lib', 'rails_admin', 'edit.rb')
require Rails.root.join('lib', 'rails_admin', 'delete.rb')
require Rails.root.join('lib', 'rails_admin', 'duplicate_team.rb')
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::SendResetPasswordEmail)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::ExportProject)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::ExportImages)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::DuplicateTeam)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Fields::Types::Yaml)

RailsAdmin.config do |config|

  ### Popular gems integration

  config.parent_controller = 'ApplicationController'

  ## == Devise ==
  config.authenticate_with(&:authenticated?)
  config.current_user_method(&:current_api_user)

  # == Cancan ==
  config.authorize_with :cancan, AdminAbility

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar true

  config.actions do
    dashboard # mandatory
    index     # mandatory
    new
    export
    bulk_delete
    show do
      except ['TeamBotInstallation']
    end
    edit do
      except ['TeamBotInstallation']
    end
    delete
    send_reset_password_email
    export_project do
      only ['Project']
    end
    export_images do
      only ['Project']
    end
    duplicate_team do
      only ['Team']
    end

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.main_app_name = ['Check']

  config.included_models = [
    'Account',
    'Annotation',
    'ApiKey',
    'Bot',
    'Bounce',
    'Claim',
    'Link',
    'Media',
    'Project',
    'ProjectMedia',
    'Source',
    'Team',
    'TeamUser',
    'User',
    'BotUser',
    'TeamBotInstallation',
    'Dynamic'
  ]

  config.navigation_static_links = {
    'Web Client' => CONFIG['checkdesk_client'],
    'Check API Explorer' => '/api',
    'GraphiQL' => '/graphiql',
    'Sidekiq' => '/sidekiq',
    'PG Hero' => '/pghero',
    'Pender API Explorer' => "#{CONFIG['pender_url']}/api",
    'Alegre API Explorer' => "#{CONFIG['alegre_host']}"
  }

  config.navigation_static_label = 'External Tools'

  def annotation_config(_type, specific_data = [])
    list do
      field :annotation_type
      field :annotated do
        pretty_value do
          path = bindings[:view].show_path(model_name: bindings[:object].annotated_type, id: bindings[:object].annotated_id)
          bindings[:view].tag(:a, href: path) << "#{bindings[:object].annotated_type} ##{bindings[:object].annotated_id}"
        end
      end
      field :annotator do
        pretty_value do
          if bindings[:object].annotator
            path = bindings[:view].show_path(model_name: bindings[:object].annotator_type, id: bindings[:object].annotator_id)
            bindings[:view].tag(:a, href: path) << "#{bindings[:object].annotator_type} ##{bindings[:object].annotator_id}"
          else
            ''
          end
        end
      end
    end

    edit do
      field :annotation_type do
        read_only true
      end
      field :annotated_type
      field :annotated_id
      field :annotator_type
      field :annotator_id
      specific_data.each do |field_name|
        field field_name
      end
      field :entities
    end

    show do
      specific_data.each do |field|
        configure field do
          visible true
        end
      end
      exclude_fields :data
    end

  end

  def media_config
    edit do
      field :type, :enum do
        enum do
          Media.types
        end
      end
     include_all_fields
    end
  end

  def visible_only_for_admin
    visible do
      bindings[:view]._current_user.is_admin?
    end
  end

  def visible_only_for_existing
    hide do
      bindings[:object].new_record?
    end
  end

  def formatted_yaml(method_name)
    formatted_value do
      begin
        JSON.pretty_generate(bindings[:object].send(method_name))
      rescue JSON::GeneratorError
        nil
      end
    end
  end

  config.model 'ApiKey' do
    label 'API Key'
    label_plural 'API Keys'

    list do
      field :access_token
      field :expire_at
    end

    create do
      field :expire_at do
        strftime_format "%Y-%m-%d"
      end
    end

    edit do
      field :expire_at do
        strftime_format "%Y-%m-%d"
      end
    end
  end

  config.model 'Media' do
    media_config
  end

  config.model 'Link' do
    media_config
  end

  config.model 'Claim' do
    media_config
  end

  config.model 'Project' do
    object_label_method do
      :admin_label
    end

    list do
      field :id
      field :title
      field :description
      field :team
      field :archived do
        visible_only_for_admin
      end
    end

    show do
      configure :get_slack_notifications_enabled do
        label 'Enable Slack notifications'
      end
      configure :get_slack_channel do
        label 'Slack channel'
      end
    end

    edit do
      field :title
      field :description
      field :team
      field :archived
      field :lead_image
      field :user
      field :slack_notifications_enabled, :boolean do
        label 'Enable Slack notifications'
        formatted_value{ bindings[:object].get_slack_notifications_enabled }
        visible_only_for_existing
      end
      field :slack_channel do
        label 'Slack channel'
        formatted_value{ bindings[:object].get_slack_channel }
        partial 'form_settings_field'
        visible_only_for_existing
      end
    end
  end

  config.model 'Team' do
    list do
      field :id
      field :name
      field :description
      field :slug
      field :inactive
      field :private do
        visible_only_for_admin
      end
      field :archived do
        visible_only_for_admin
      end
    end

    show do
      id = CONFIG['default_project_media_workflow']
      configure "get_media_#{id.pluralize}", :json do
        label "Media #{id.pluralize.tr('_', ' ')}"
      end
      configure :get_slack_notifications_enabled do
        label 'Enable Slack notifications'
      end
      configure :get_slack_webhook do
        label 'Slack webhook'
      end
      configure :get_slack_channel do
        label 'Slack channel'
      end
      configure :private do
        visible_only_for_admin
      end
      configure :projects do
        visible_only_for_admin
      end
      configure :users do
        visible_only_for_admin
      end
      configure :settings do
        hide
      end
      configure :accounts do
        eager_load false
        hide
      end
      configure :team_users do
        eager_load false
        hide
      end
      configure :sources do
        eager_load false
        hide
      end
      configure :project_medias do
        eager_load false
        hide
      end
    end

    edit do
      field :name do
        visible_only_for_admin
      end

      field :description do
        visible_only_for_admin
      end

      field :logo do
        visible_only_for_admin
      end

      field :slug do
        visible_only_for_admin
        help 'Accepts only letters, numbers and hyphens.'
      end

      field :private do
        visible_only_for_admin
      end

      field :archived do
        visible_only_for_admin
      end

      field :max_number_of_members do
        label 'Maximum number of members'
        formatted_value{ bindings[:object].get_max_number_of_members }
        visible_only_for_admin
      end

      id = CONFIG['default_project_media_workflow']
      field "media_#{id.pluralize}", :yaml do
        partial 'json_editor'
        help "A list of custom #{id.pluralize.tr('_', ' ')} for items that match your team's guidelines."
      end

      field :slack_notifications_enabled, :boolean do
        label 'Enable Slack notifications'
        formatted_value{ bindings[:object].get_slack_notifications_enabled }
        visible_only_for_existing
      end

      field :slack_webhook do
        partial 'form_settings_field'
        label 'Slack webhook'
        help 'A <a href="https://my.slack.com/services/new/incoming-webhook/" target="_blank" rel="noopener noreferrer">webhook supplied by Slack</a> and that Check uses to send notifications about events that occur in your team.'.html_safe
        formatted_value{ bindings[:object].get_slack_webhook }
        visible_only_for_existing
      end

      field :slack_channel do
        partial 'form_settings_field'
        label 'Slack channel'
        help 'The Slack channel to which Check should send notifications about events that occur in your workspace.'
        formatted_value{ bindings[:object].get_slack_channel }
        visible_only_for_existing
      end
    end

  end

  config.model 'TeamUser' do
    list do
      field :team
      field :user
      field :role
      field :status
    end

    edit do
      field :team
      field :user
      field :role, :enum do
        enum do
          TeamUser.role_types
        end
      end
      field :status, :enum do
        enum do
          TeamUser.status_types
        end
      end
    end
  end

  config.model 'User' do
    list do
      field :name
      field :login
      field :email
      field :is_admin do
        visible_only_for_admin
      end
      field :is_active
    end

    show do
      configure :get_send_email_notifications do
        label 'Email notifications'
      end
    end

    edit do
      field :name
      field :login
      field :password do
        visible_only_for_admin
        visible do
          bindings[:object].encrypted_password?
        end
        formatted_value do
          '****'
        end
      end
      field :email
      field :image
      field :current_team_id
      field :is_admin do
        visible_only_for_admin
      end
      field :is_active do
        visible_only_for_admin
      end
      field :send_email_notifications, :boolean do
        label 'Email notifications'
        formatted_value{ bindings[:object].get_send_email_notifications ? "Yes" : "No" }
      end
    end
  end

  config.model 'BotUser' do
    label 'Bot User'
    label_plural 'Bot Users'

    list do
      field :name
      field :login
      field :api_key
    end

    show do
      field :name
      field :login
      field :image
      field :api_key
    end

    edit do
      field :name
      field :login
      field :image
      field :api_key
      field :settings do
        label 'Settings'
        formatted_yaml(:settings)
      end
    end
  end

  config.model 'ProjectMedia' do
    label 'ProjectMedia'
    list do
      configure :project do
        queryable true
        searchable [:title, :id]
      end
    end
  end

  config.model 'TeamBotInstallation' do
    list do
      field :bot_user
      field :team
    end
  end

  config.model 'Dynamic' do
    label 'Smooch User'
    label_plural 'Smooch Users'

    list do
      scopes [:smooch_user]
      field :id
      field :name do
        queryable true
        filterable true
        searchable [{ dynamic_annotation_fields: :value }]
        formatted_value do
          begin
            dynamic = bindings[:object]
            data = JSON.parse(dynamic.get_field_value('smooch_user_data'))
            data.dig('raw', 'givenName').to_s + ' ' + data.dig('raw', 'surname').to_s
          rescue
            'Could not parse the name'
          end
        end
        visible_only_for_admin
      end
    end
  end
end
