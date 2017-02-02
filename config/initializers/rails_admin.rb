RailsAdmin.config do |config|

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate!
  end
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

    list do
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
      field :text
      field :entities
    end

    edit do
      field :annotation_type do
        def value
          'comment'
        end
      end
      field :annotated_type, :enum do
        enum do
          Comment.types
        end
        help ''
      end
      field :annotated_id
      field :annotator_type
      field :annotator_id
      field :data do
        partial 'settings'
      end
      field :entities
    end
  end

  config.model 'Project' do

    list do
      field :title
      field :description
      field :team
      field :archived
    end

    edit do
      field :title
      field :description
      field :team
      field :archived
      field :lead_image
      field :user
      field :settings do
        partial 'settings'
      end
    end

    create do
      field :title
      field :description
      field :team
      field :archived
      field :lead_image
      field :user
      field :settings
    end

  end

  config.model 'Team' do

    list do
      field :name
      field :description
      field :subdomain
      field :private
      field :archived
    end

    edit do
      field :name
      field :description
      field :logo
      field :subdomain
      field :private
      field :archived
      field :settings do
        partial 'settings'
      end
    end

    create do
      field :name
      field :description
      field :logo
      field :subdomain
      field :private
      field :archived
      field :settings
    end

  end

  config.model 'User' do

    list do
      field :name
      field :login
      field :provider
      field :email
    end

    edit do
      field :name
      field :login
      field :provider
      field :email
      field :profile_image
      field :image
      field :current_team_id
    end

    create do
      field :name
      field :login
      field :provider
      field :email do
        help 'Required'
      end
      field :profile_image
      field :image
      field :current_team_id
    end

  end

end
