module CheckBasicAbilities
  include CanCan::Ability

  def global_admin_perms
    can :access, :rails_admin
    can :dashboard
    can :manage, :all
  end

  def authenticated_perms
    can :create, Team
    can :create, TeamUser, :user_id => @user.id, status: ['member', 'requested']

    # Permissions for registration and login
    can :create, Source, :user_id => @user.id
    can :update, User, :id => @user.id
    can [:create, :update], Account, :user_id => @user.id
    can :create, Embed, :annotated_id => @user.account_ids
  end

  # Extra permissions for all users
  def extra_perms_for_all_users
    can :create, [User, AccountSource]
    can :create, PaperTrail::Version
    can :read, Team, :private => false
    can :read, Team, :private => true,  id: @user.cached_teams

    # A @user can read a user if:
    # 1) @user is the same as target user
    # 2) target user is a member of at least one public team
    # 3) @user is a member of at least one same team as the target user
    can :read, User, id: @user.id
    can :read, User, teams: { private: false }
    can :read, User, team_users: { status: 'member', team_id: @user.cached_teams }

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
    can :read, [ProjectMedia, ProjectSource], project: { team: { private: false } }
    can :read, [ProjectMedia, ProjectSource], project: { team_id: @user.cached_teams }

    %w(comment flag status embed tag dynamic task annotation).each do |annotation_type|
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

    cannot :manage, ApiKey
    cannot :manage, BotUser
  end
end
