module CheckBasicAbilities
  include CanCan::Ability

  def can_list(klasses, new_params)
    klasses = [klasses].flatten
    RequestStore.store[:graphql_connection_params] ||= {}
    key = "#{@user.id}:#{@context_team.id}"
    RequestStore.store[:graphql_connection_params][key] ||= {}
    all_params = RequestStore.store[:graphql_connection_params][key]
    klasses.each do |klass|
      current_params = all_params[klass.to_s] || {}
      params = current_params.merge(new_params)
      RequestStore.store[:graphql_connection_params][key][klass.to_s] = params.with_indifferent_access
    end
  end

  def global_admin_perms
    can :access, :rails_admin
    can :dashboard
    can :manage, :all
  end

  def authenticated_perms
    can :create, Team
    can :create, TeamUser, :user_id => @user.id, status: ['member', 'requested']
    can :update, TeamUser do |obj|
      obj.user_id == @user.id && obj.user_id_was == obj.user_id && obj.role_was == obj.role && obj.status_was == 'member' && obj.status == 'banned'
    end

    # Permissions for registration and login
    can :create, Source, :user_id => @user.id
    can :update, Source, :id => @user.source_id
    can :destroy, AccountSource, source: { team_id: nil, id: @user.source_id}
    can [:update, :destroy], User, :id => @user.id
    can [:create, :update], Account, :user_id => @user.id
    can [:destroy, :create], [Dynamic, Annotation], :annotation_type => 'metadata', :annotated_type => 'Account', :annotated_id => @user.account_ids
    can :destroy, DynamicAnnotation::Field, annotation: { annotation_type: 'metadata', annotated_type: 'Account', annotated_id: @user.account_ids }
    can :destroy, [Dynamic, Annotation], :annotation_type => 'metadata', :annotated_type => 'Account', :annotated_id => @user.frozen_account_ids
    can :destroy, DynamicAnnotation::Field, annotation: { annotation_type: 'metadata', annotated_type: 'Account', annotated_id: @user.frozen_account_ids }
    can :destroy, [Dynamic, Annotation], :annotation_type => 'metadata', :annotated_type => 'Source', :annotated_id => @user.frozen_source_id
    can :destroy, DynamicAnnotation::Field, annotation: { annotation_type: 'metadata', annotated_type: 'Source', annotated_id: @user.frozen_source_id }

    can :restore, ProjectMedia do |obj|
      tmp = obj.dup
      tmp.archived = false
      obj.archived && can?(:update, tmp)
    end
  end

  # Extra permissions for all users
  def extra_perms_for_all_users
    can :create, [User, AccountSource]
    can :create, Version
    can :read, Team, :private => false
    can :read, Team, :private => true,  id: @user.cached_teams
    can_list Team, { inactive: false }
    can_list ProjectMedia, { inactive: false }
    can_list Project, { 'joins' => :team, 'teams.inactive' => false }
    cannot :manage, BotUser

    # A @user can read a user if:
    # 1) @user is the same as target user
    # 2) target user is a member of at least one public team
    # 3) @user is a member of at least one same team as the target user
    can :read, User, id: @user.id
    can :read, [User, BotUser], teams: { private: false }
    can :read, [User, BotUser], team_users: { status: ['member', 'requested'], team_id: @user.cached_teams }

    # A @user can read contact, project or team user if:
    # 1) team is private and @user is a member of that team
    # 2) team user is not private
    can :read, [Contact, Project, TeamUser], team_id: @user.cached_teams
    can :read, [Contact, Project, TeamUser], team: { private: false }

    # A @user can read any of those objects if:
    # 1) it's a source related to him/her or not related to any user
    # 2) it's related to at least one public team
    # 3) it's related to a private team which the @user has access to
    can :read, [Account, ProjectMedia, Source], user_id: [@user.id, nil]
    can :read, [Source, Media, Link, Claim], projects: { team: { private: false }}
    can :read, [Source, Media, Link, Claim], projects: { team_id: @user.cached_teams }

    can :read, [Account, ProjectSource], source: { user_id: [@user.id, nil] }
    can :read, Account, source: { projects: { team_id: @user.cached_teams }}
    can :read, Relationship, { source: { team_id: @user.cached_teams }, target: { team_id: @user.cached_teams } }
    can :read, ProjectSource, project: { team: { private: false } }
    can :read, ProjectSource, project: { team_id: @user.cached_teams }
    can :read, ProjectMedia do |obj|
      obj.team ||= obj.project.team
      !obj.team.private || @user.cached_teams.include?(obj.team.id)
    end

    can :read, BotUser do |obj|
      obj.get_approved || @user.cached_teams.include?(obj.team_author_id)
    end

    annotation_perms_for_all_users

    cannot :manage, ApiKey

    can [:create, :update], LoginActivity

    cannot :find_by_json_fields, DynamicAnnotation::Field

    can [:read, :create], Shortener::ShortenedUrl
  end

  def annotation_perms_for_all_users
    %w(comment tag dynamic task annotation).each do |annotation_type|
      can :read, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        team_ids = obj.get_team
        teams = Team.where(id: team_ids, private: false)
        if teams.empty?
          TeamUser.where(user_id: @user.id, team_id: team_ids, status: 'member').exists?
        else
          teams.any?
        end
      end
    end
  end
end
