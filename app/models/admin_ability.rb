class AdminAbility
  include CheckBasicAbilities

  def initialize(user = nil)
    alias_action :create, :read, :update, :destroy, :to => :crud
    @user = User.current ||= user || User.new
    @teams = @user.teams_owned.map(&:id)
    # Define User abilities
    if @user.is_admin?
      global_admin_perms
    else
      if @user.id
        authenticated_perms
      end
      if @teams.any?
        owner_perms
      end
    end
  end

  private

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can [:read, :update, :destroy], User, team_users: { team_id: @teams, status: 'member'  }

    can :create, Team
    can [:read, :update, :destroy], Team, :id => @teams
    can :create, TeamUser, :team_id => @teams, role: ['owner', 'editor', 'journalist', 'contributor']
    can [:read, :update], TeamUser, team_id: @teams
    can :destroy, TeamUser, user_id: @user.id
    cannot :update, TeamUser, team_id: @teams, user_id: @user.id
    can [:crud], Contact, team_id: @teams
    can [:create, :read, :update], Project, team_id: @teams
    can :update, Project, team_id: @teams, user_id: @user.id
    can :destroy, Project, team_id: @teams
    can :export_project, Project, team_id: @teams

    can :create, [Media, Comment, Embed, Link, Claim, Dynamic]
    can :update, [Media, Link, Claim], :user_id => @user.id
    can [:read, :update, :destroy], [Media, Link, Claim], projects: { team: { id: @teams }}
    can :update, Embed, annotated: { project: { team: { id: @teams }}}
    can [:crud], [ProjectSource, ProjectMedia], project: { team: { id: @teams }}
    can [:cud], [Source, Account], :team_id => @teams
    can :read, [Account, Source], user_id: [@user.id, nil]
    %w(annotation comment flag status embed dynamic task).each do |annotation_type|
      can [:crud], annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        (obj.get_team & @teams).any?
      end
    end
    can [:create, :read, :destroy], Tag, ['annotation_type = ?', 'tag'] do |obj|
      (obj.get_team & @teams).any?
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
    can :create, PaperTrail::Version
    can :destroy, PaperTrail::Version do |obj|
      teams = []
      v_obj = obj.item_type.constantize.find(obj.item_id)
      teams = v_obj.get_team if v_obj.respond_to?(:get_team)
      teams << v_obj.team_id if teams.blank? and v_obj.respond_to?(:team)
      teams << v_obj.project.team_id if teams.blank? and v_obj.respond_to?(:project)
      (teams & @teams).any?
    end
  end

end
