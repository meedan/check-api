class AdminAbility
  include CanCan::Ability

  def initialize(user = nil)
    @user = User.current ||= user || User.new
    @teams = @user.teams_owned.map(&:id)
    # Define User abilities
    if @user.is_admin?
      global_admin_perms
    else
      extra_perms_for_all_users
      if @user.id
        authenticated_perms
      end
      if @teams.any?
        owner_perms
      end
    end
  end

  private

  def global_admin_perms
    can :access, :rails_admin
    can :dashboard
    can :manage, :all
  end

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can [:update, :destroy], User, :team_users => { :team_id => @teams, role: ['owner', 'editor', 'journalist', 'contributor'] }

    can :create, Team
    can [:update, :destroy], Team, :id => @teams
    can :create, TeamUser, :team_id => @teams, role: ['owner', 'editor', 'journalist', 'contributor']
    can :update, TeamUser, team_id: @teams
    can :destroy, TeamUser, user_id: @user.id
    cannot :update, TeamUser, team_id: @teams, user_id: @user.id
    can [:create, :update, :destroy], Contact, :team_id => @teams
    can [:create, :update], Project, :team_id => @teams
    can :update, Project, :team_id => @teams, :user_id => @user.id
    can :destroy, Project, :team_id => @teams
    can :export_project, Project, team_id: @teams

    can :create, [Media, Account, Source, Comment, Embed, Link, Claim, Dynamic]
    can :update, [Media, Link, Claim], :user_id => @user.id
    can :update, [Media, Link, Claim], projects: { team: { id: @teams }}
    can [:update, :destroy], [Media, Link, Claim] do |obj|
      (obj.get_team & @teams).any?
    end
    can :update, [Account, Source, Embed]
    can [:create, :update], [ProjectSource, ProjectMedia], project: { team: { id: @teams }}
    can :destroy, [ProjectMedia, ProjectSource], project: { team: { id: @teams }}
    %w(annotation comment flag status tag embed dynamic task).each do |annotation_type|
      can [:create, :destroy], annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        (obj.get_team & @teams).any?
      end
    end
    %w(annotation comment flag status embed dynamic task).each do |annotation_type|
      can [:update], annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        (obj.get_team & @teams).any?
      end
    end
    can [:destroy, :update], [Dynamic, Annotation, Task] do |obj|
      obj.annotator_id.to_i == @user.id
    end
    can [:create, :update, :destroy], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id == @user.id
    end
    can :update, [Dynamic, Annotation] do |obj|
      (obj.get_team & @teams).any?
    end
    can :update, DynamicAnnotation::Field do |obj|
      (obj.annotation.get_team & @teams).any?
    end
    can :update, Task, ['annotation_type = ?', 'task'] do |obj|
      before, after = obj.data_change
      changes = (after.to_a - before.to_a).to_h
      (obj.get_team & @teams).any? && changes.keys == ['status']
    end
    can :destroy, PaperTrail::Version do |obj|
      teams = []
      v_obj = obj.item_type.constantize.find(obj.item_id)
      teams = v_obj.get_team if v_obj.respond_to?(:get_team)
      teams << v_obj.team_id if teams.blank? and v_obj.respond_to?(:team)
      teams << v_obj.project.team_id if teams.blank? and v_obj.respond_to?(:project)
      (teams & @teams).any?
    end
  end

  def authenticated_perms
    can :create, Team
    can :create, TeamUser, :user_id => @user.id, status: ['member', 'requested']

    # Permissions for registration and login
    can :create, Source, :user_id => @user.id
    can :update, User, :id => @user.id
    can :create, Account, :user_id => @user.id
    can :create, Embed, :annotated_id => @user.account_ids
  end

  # Extra permissions for all users
  def extra_perms_for_all_users
    can :create, User
    can :create, PaperTrail::Version
    can :read, Team, :private => false
    can :read, Team, :private => true, :team_users => { :user_id => @user.id, :status => 'member' }

    # A @user can read a user if:
    # 1) @user is the same as target user
    # 2) target user is a member of at least one public team
    # 3) @user is a member of at least one same team as the target user
    can :read, User, id: @user.id
    can :read, User, teams: { private: false }
    can :read, User, team_users: { status: 'member', team: { team_users: { user_id: @user.id, status: 'member' }}}

    # A @user can read contact, project or team user if:
    # 1) team is private and @user is a member of that team
    # 2) team user is not private
    can :read, [Contact, Project, TeamUser], team: { team_users: { user_id: @user.id, status: 'member'} }
    can :read, [Contact, Project, TeamUser], team: { private: false }

    # A @user can read any of those objects if:
    # 1) it's a source related to him/her or not related to any user
    # 2) it's related to at least one public team
    # 3) it's related to a private team which the @user has access to
    can :read, [Account, ProjectMedia, Source], user_id: [@user.id, nil]
    can :read, [Source, Media, Link, Claim], projects: { team: { private: false }}
    can :read, [Source, Media, Link, Claim], projects: { team: { team_users: { user_id: @user.id, status: 'member' }}}

    can :read, [Account, ProjectSource], source: { user_id: [@user.id, nil] }
    can :read, Account, source: { projects: { team: { private: false, team_users: { user_id: @user.id }}}}
    can :read, Account, source: { projects: { team: { team_users: { user_id: @user.id, status: 'member' }}}}
    can :read, [ProjectMedia, ProjectSource], project: { team: { private: false } }
    can :read, [ProjectMedia, ProjectSource], project: { team: { team_users: { user_id: @user.id, status: 'member' }}}

    %w(comment flag status embed tag dynamic task annotation).each do |annotation_type|
      can :read, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        team_ids = obj.get_team
        teams = Team.where(id: team_ids, private: false)
        if teams.empty?
          tu = TeamUser.where(user_id: @user.id, team_id: team_ids, status: 'member')
          TeamUser.where(user_id: @user.id, team_id: team_ids, status: 'member').exists?
        else
          teams.any?
        end
      end
    end

    cannot :manage, ApiKey
  end
end
