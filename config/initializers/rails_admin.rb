require Rails.root.join('lib', 'rails_admin', 'send_reset_password_email.rb')
require Rails.root.join('lib', 'rails_admin', 'export_project.rb')
require Rails.root.join('lib', 'rails_admin', 'yaml_field.rb')
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::SendResetPasswordEmail)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::ExportProject)
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
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar true

  config.actions do
    dashboard do
      # https://github.com/sferik/rails_admin/wiki/Dashboard-action#disabling-record-count-bars
      statistics false
    end
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    send_reset_password_email
    export_project do
      only ['Project']
    end

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.main_app_name = ['Check']

  config.included_models = ['Account', 'Annotation', 'ApiKey', 'Bot', 'Bounce', 'Claim', 'Comment', 'Contact', 'Embed', 'Flag', 'Link', 'Media', 'Project', 'ProjectMedia', 'ProjectSource', 'Source', 'Status', 'Tag', 'Team', 'TeamUser', 'User', 'BotUser']

  config.navigation_static_links = {
    'API Explorer' => '/api',
    'GraphiQL' => '/graphiql',
    'Web Client' => CONFIG['checkdesk_client']
  }

  config.navigation_static_label = 'External Tools'

  def annotation_config(type, specific_data = [])
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
          path = bindings[:view].show_path(model_name: bindings[:object].annotator_type, id: bindings[:object].annotator_id)
          bindings[:view].tag(:a, href: path) << "#{bindings[:object].annotator_type} ##{bindings[:object].annotator_id}"
        end
      end
    end

    edit do
      field :annotation_type do
        read_only true
        help ''
      end
      field :annotated_type, :enum do
        enum do
          type.classify.constantize.annotated_types
        end
      end
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

  def render_settings(field_type)
    partial "form_settings_#{field_type}"
    hide do
      bindings[:object].new_record?
    end
  end

  def visible_only_for_admin
    visible do
      bindings[:view]._current_user.is_admin?
    end
  end

  def visible_only_for_allowed_teams(setting)
    visible do
      bindings[:object].send("get_limits_#{setting}") != false
    end
  end

  config.model 'ApiKey' do
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

  config.model 'Comment' do
    annotation_config('comment', [:text])
    parent Annotation
  end

  config.model 'Embed' do
    annotation_config('embed', [:title, :description, :embed, :username, :published_at])
    parent Annotation
  end

  config.model 'Flag' do
    annotation_config('flag', [:flag])
    parent Annotation

    edit do
      field :flag, :enum do
        enum do
          Flag.flag_types
        end
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

  config.model 'Status' do
    annotation_config('status', [:status])
    parent Annotation

    edit do
      field :status, :enum do
        enum do
          annotated, context = bindings[:object].get_annotated_and_context
          Status.possible_values(annotated, context)[:statuses].collect { |s| s[:id]}
        end
      end
    end

    create do
      field :status do
        hide
      end
    end

  end

  config.model 'Tag' do
    annotation_config('tag', [:tag, :full_tag])
    parent Annotation
  end

  config.model 'Project' do
    object_label_method do
      :admin_label
    end

    list do
      field :title
      field :description
      field :team
      field :archived
      field :settings do
        label 'Link to authorize Bridge to publish translations automatically'
        formatted_value do
          project = bindings[:object]
          token = project.token
          host = CONFIG['checkdesk_base_url']
          %w(twitter facebook).collect do |p|
            dest = "#{host}/api/admin/project/#{project.id}/add_publisher/#{p}?token=#{token}"
            link = "#{host}/api/users/auth/#{p}?destination=#{dest}"
            bindings[:view].link_to(p.capitalize, link)
          end.join(' | ').html_safe
        end
      end
    end

    show do
      configure :get_viber_token do
        label 'Viber token'
      end
      configure :get_slack_notifications_enabled do
        label 'Enable Slack notifications'
      end
      configure :get_slack_channel do
        label 'Slack #channel'
      end
      configure :get_languages, :json do
        label 'Languages'
      end
    end

    edit do
      field :title
      field :description
      field :team do
      end
      field :archived
      field :lead_image
      field :user
      field :slack_notifications_enabled, :boolean do
        label 'Enable Slack notifications'
        formatted_value{ bindings[:object].get_slack_notifications_enabled }
        help ''
        hide do
          bindings[:object].new_record?
        end
      end
      field :viber_token do
        label 'Viber token'
        formatted_value{ bindings[:object].get_viber_token }
        help ''
        hide do
          bindings[:object].new_record?
        end
      end
      field :slack_channel do
        label 'Slack default #channel'
        formatted_value{ bindings[:object].get_slack_channel }
        help 'The Slack channel to which Check should send notifications about events that occur in this project.'
        render_settings('field')
      end
      field :languages, :yaml do
        label 'Languages'
        help "A list of the project's preferred languages for machine translation (e.g. ['ar', 'fr'])."
      end
    end
  end

  config.model 'Team' do

    list do
      field :name
      field :description
      field :slug
      field :private do
        visible_only_for_admin
      end
      field :archived do
        visible_only_for_admin
      end
    end

    show do
      configure :get_media_verification_statuses, :json do
        label 'Media verification statuses'
      end
      configure :get_source_verification_statuses, :json do
        label 'Source verification statuses'
      end
      configure :get_keep_enabled do
        label 'Enable Keep archiving'
        visible_only_for_admin
      end
      configure :get_slack_notifications_enabled do
        label 'Enable Slack notifications'
      end
      configure :get_slack_webhook do
        label 'Slack webhook'
      end
      configure :get_slack_channel do
        label 'Slack default #channel'
      end
      configure :get_checklist, :json do
        label 'Checklist'
      end
      configure :get_suggested_tags do
        label 'Suggested tags'
        visible_only_for_admin
      end
      configure :private do
        visible_only_for_admin
      end
      configure :projects do
        visible_only_for_admin
      end
      configure :accounts do
        visible_only_for_admin
      end
      configure :team_users do
        visible_only_for_admin
      end
      configure :users do
        visible_only_for_admin
      end
      configure :sources do
        visible_only_for_admin
      end
      configure :settings do
        hide
      end
    end

    edit do
      field :name do
        read_only true
        help ''
      end
      field :description do
        visible_only_for_admin
      end
      field :logo do
        visible_only_for_admin
      end
      field :slug do
        read_only true
        help ''
      end
      field :private do
        visible_only_for_admin
      end
      field :archived do
        visible_only_for_admin
      end
      field :media_verification_statuses, :yaml do
        partial "json_editor"
        help "A list of custom verification statuses for reports that match your team's journalistic guidelines."
        visible_only_for_allowed_teams 'custom_statuses'
      end
      field :source_verification_statuses, :yaml do
        partial "json_editor"
        help "A list of custom verification statuses for sources that match your team's journalistic guidelines."
        visible_only_for_allowed_teams 'custom_statuses'
      end
      field :keep_enabled, :boolean do
        label 'Enable Keep archiving'
        formatted_value{ bindings[:object].get_keep_enabled }
        help ''
        hide do
          bindings[:object].new_record?
        end
        visible_only_for_admin
        visible_only_for_allowed_teams 'keep_integration'
      end
      field :slack_notifications_enabled, :boolean do
        label 'Enable Slack notifications'
        formatted_value{ bindings[:object].get_slack_notifications_enabled }
        help ''
        hide do
          bindings[:object].new_record?
        end
        visible_only_for_allowed_teams 'slack_integration'
      end
      field :slack_webhook do
        label 'Slack webhook'
        formatted_value{ bindings[:object].get_slack_webhook }
        help "A <a href='https://my.slack.com/services/new/incoming-webhook/' target='_blank'>webhook supplied by Slack</a> and that Check uses to send notifications about events that occur in your team.".html_safe
        render_settings('field')
        visible_only_for_allowed_teams 'slack_integration'
      end
      field :slack_channel do
        label 'Slack default #channel'
        formatted_value{ bindings[:object].get_slack_channel }
        help "The Slack channel to which Check should send notifications about events that occur in your team."
        render_settings('field')
        visible_only_for_allowed_teams 'slack_integration'
      end
      field :checklist, :yaml do
        partial "json_editor"
        help "A list of tasks that should be automatically created every time a new report is added to a project in your team."
        visible_only_for_allowed_teams 'custom_tasks_list'
      end
      field :suggested_tags do
        label 'Suggested tags'
        formatted_value { bindings[:object].get_suggested_tags }
        help "A list of common tags to be used with reports and sources in your team."
        render_settings('field')
        visible_only_for_admin
      end
      field :limits, :yaml do
        label 'Limits'
        formatted_value { bindings[:object].limits.to_yaml }
        help "Limit this team features"
        render_settings('text')
        visible_only_for_admin
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
      field :provider
      field :email
      field :is_admin do
        visible do
          bindings[:view]._current_user.is_admin?
        end
      end
    end

    show do
      configure :get_languages, :json do
        label 'Languages'
      end
    end

    edit do
      field :name
      field :login
      field :provider do
        visible do
          bindings[:view]._current_user.is_admin? && bindings[:object].email.blank?
        end
      end
      field :password do
        visible do
          bindings[:view]._current_user.is_admin? && bindings[:object].provider.blank?
        end
        formatted_value do
         ''
        end
      end
      field :email
      field :profile_image
      field :image
      field :current_team_id
      field :is_admin do
        visible do
          bindings[:view]._current_user.is_admin?
        end
      end
      field :languages, :yaml do
        label 'Languages'
        render_settings('text')
        help "A list of the user's preferred languages (e.g. for translation)."
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
      field :api_key
    end

    edit do
      field :name
      field :login
      field :profile_image
      field :image
      field :api_key
    end
  end
end
