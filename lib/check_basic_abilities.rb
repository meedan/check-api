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
    can :manage, :all
  end

  def authenticated_perms
    # Permissions for registration and login
    can :read, Source, team_id: @context_team.id
    can :create, Source, :user_id => @user.id, team_id: nil
    can :update, Source, :id => @user.source_id, team_id: nil
    can :read, AccountSource, source: { user_id: @user.id }
    can :destroy, AccountSource, source: { team_id: nil, id: @user.source_id}
    can [:update, :destroy], User, :id => @user.id
    can [:create, :update], Account, :user_id => @user.id
    can [:destroy, :create], [Dynamic, Annotation], :annotation_type => 'metadata', :annotated_type => 'Account', :annotated_id => @user.account_ids
    can :destroy, DynamicAnnotation::Field, annotation: { annotation_type: 'metadata', annotated_type: 'Account', annotated_id: @user.account_ids }
    can :destroy, [Dynamic, Annotation], :annotation_type => 'metadata', :annotated_type => 'Account', :annotated_id => @user.frozen_account_ids
    can :destroy, DynamicAnnotation::Field, annotation: { annotation_type: 'metadata', annotated_type: 'Account', annotated_id: @user.frozen_account_ids }
    can :destroy, [Dynamic, Annotation], :annotation_type => 'metadata', :annotated_type => 'Source', :annotated_id => @user.frozen_source_id
    can :destroy, DynamicAnnotation::Field, annotation: { annotation_type: 'metadata', annotated_type: 'Source', annotated_id: @user.frozen_source_id }

    can [:restore, :confirm, :not_spam], ProjectMedia do |obj|
      tmp = obj.dup
      tmp.archived = CheckArchivedFlags::FlagCodes::NONE
      can?(:update, tmp)
    end
  end

  # Extra permissions for all users
  def extra_perms_for_all_users
    can :create, [User, AccountSource]
    can :create, Version
    can :read, Team, :private => false
    can :read, Team, :private => true,  id: @user.cached_teams
    can_list Team, { inactive: false }
    cannot :manage, BotUser

    # A @user can read a user if:
    # 1) @user is the same as target user
    # 2) target user is a member of at least one public team
    # 3) @user is a member of at least one same team as the target user
    can :read, User, id: @user.id
    can :read, [User, BotUser], teams: { private: false }
    can :read, [User, BotUser], team_users: { status: ['member', 'requested'], team_id: @user.cached_teams }

    # A @user can read project or team user if:
    # 1) team is private and @user is a member of that team
    # 2) team user is not private
    can :read, [TeamUser, SavedSearch], team_id: @user.cached_teams
    can :read, [TeamUser, SavedSearch], team: { private: false }

    # A @user can read any of those objects if:
    # 1) it's a source related to him/her or not related to any user
    # 2) it's related to at least one public team
    # 3) it's related to a private team which the @user has access to
    can :read, [Account, ProjectMedia, Source], user_id: [@user.id, nil]
    can :read, [Media, Link, Claim], project_medias: { team: { private: false } }
    can :read, [Media, Link, Claim], project_medias: { team_id: @user.cached_teams }

    can :read, Account, source: { user_id: [@user.id, nil] }
    can :read, Relationship, { source: { team_id: @user.cached_teams }, target: { team_id: @user.cached_teams } }
    can :read, ProjectMedia do |obj|
      !obj.team.private || @user.cached_teams.include?(obj.team.id)
    end

    can :read, BotUser do |obj|
      obj.get_approved || @user.cached_teams.include?(obj.team_author_id)
    end

    can [:read, :create, :update, :destroy], ProjectMediaUser do |obj|
      obj.user_id == @user.id
    end

    can [:read, :create], TiplineMessage do |obj|
      @user.cached_teams.include?(obj.team_id)
    end

    annotation_perms_for_all_users

    cannot :manage, ApiKey

    can [:create, :update], LoginActivity

    cannot :find_by_json_fields, DynamicAnnotation::Field

    can [:read, :create], Shortener::ShortenedUrl

    can :read, Feed do |obj|
      !(@user.cached_teams & obj.team_ids).empty?
    end

    can :read, Cluster do |obj|
      !(@user.cached_teams & obj.feed.team_ids).empty?
    end

    can :read, FeedTeam do |obj|
      @user.cached_teams.include?(obj.team_id)
    end

    can :read, Request do |obj|
      !(@user.cached_teams & obj.feed.team_ids).empty?
    end

    can [:read, :destroy], FeedInvitation do |obj|
      @user.email == obj.email || @user.id == obj.user_id || TeamUser.where(user_id: @user.id, team_id: obj.feed.team_id, role: 'admin').exists?
    end
  end

  def annotation_perms_for_all_users
    %w(tag dynamic task annotation).each do |annotation_type|
      can :read, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        team_ids = [obj.team&.id]
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
