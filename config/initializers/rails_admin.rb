RailsAdmin.config do |config|

  ### Popular gems integration

  config.parent_controller = 'ApplicationController'

  ## == Devise ==
  config.authenticate_with(&:authenticated?)
  config.current_user_method(&:current_api_user)

  # == Cancan ==
  config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.main_app_name = ['Check']

  config.included_models = ['Account', 'Annotation', 'ApiKey', 'Bot', 'Bounce', 'Claim', 'Comment', 'Contact', 'Embed', 'Flag', 'Link', 'Media', 'Project', 'ProjectMedia', 'ProjectSource', 'Source', 'Status', 'Tag', 'Team', 'TeamUser', 'User']

  config.navigation_static_links = {
    'Home' => '/',
    'API Explorer' => '/api',
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

  config.model 'ApiKey' do
    list do
      field :access_token
      field :expire_at
    end

    create do
      field :access_token
      field :expire_at
    end

    edit do
      field :expire_at
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
    end

    show do
      configure :get_slack_notifications_enabled do
        label 'Enable Slack notifications'
      end
      configure :get_slack_channel do
        label 'Slack #channel'
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
      end
      field :slack_channel do
        label 'Slack default #channel'
        formatted_value{ bindings[:object].get_slack_channel }
      end
    end

    create do
      field :slack_notifications_enabled do
        hide
      end
      field :slack_channel do
        hide
      end
    end

  end

  config.model 'Team' do

    list do
      field :name
      field :description
      field :slug
      field :private
      field :archived
    end

    show do
      configure :get_media_verification_statuses, :json do
        label 'Media verification statuses'
      end
      configure :get_source_verification_statuses, :json do
        label 'Source verification statuses'
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
    end

    edit do
      field :name
      field :description
      field :logo
      field :slug
      field :private
      field :archived
      field :media_verification_statuses, :json do
        label 'Media verification statuses'
        formatted_value do
          statuses = bindings[:object].get_media_verification_statuses
          statuses ? JSON.pretty_generate(statuses) : ''
        end
      end
      field :source_verification_statuses, :json do
        label 'Source verification statuses'
        formatted_value do
          statuses = bindings[:object].get_source_verification_statuses
          statuses ? JSON.pretty_generate(statuses) : ''
        end
      end
      field :slack_notifications_enabled, :boolean do
        label 'Enable Slack notifications'
        formatted_value{ bindings[:object].get_slack_notifications_enabled }
      end
      field :slack_webhook do
        label 'Slack webhook'
        formatted_value{ bindings[:object].get_slack_webhook }
      end
      field :slack_channel do
        label 'Slack default #channel'
        formatted_value do
          bindings[:object].get_slack_channel
        end
      end
      field :checklist, :json do
        label 'Checklist'
        formatted_value do
          checklist = bindings[:object].get_checklist
          checklist ? JSON.pretty_generate(checklist) : ''
        end
      end
    end

    create do
      configure :media_verification_statuses do
        hide
      end
      field :source_verification_statuses do
        hide
      end
      field :slack_notifications_enabled do
        hide
      end
      field :slack_webhook do
        hide
      end
      field :slack_channel do
        hide
      end
      field :checklist do
        hide
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
      field :settings, :json do
        formatted_value do
          bindings[:object].settings.except(:password, :password_confirmation) unless bindings[:object].settings.nil?
        end
      end
    end

    create do
      configure :set_new_password do
        hide
      end
    end

    show do
      configure :settings, :json
    end

  end

end
