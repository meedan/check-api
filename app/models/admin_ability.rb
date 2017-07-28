class AdminAbility
  include CheckBasicAbilities

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

    can :create, [Media, Comment, Embed, Link, Claim, Dynamic]
    can :update, [Media, Link, Claim], :user_id => @user.id
    can :update, [Media, Link, Claim], projects: { team: { id: @teams }}
    can [:update, :destroy], [Media, Link, Claim] do |obj|
      (obj.get_team & @teams).any?
    end
    can :update, Embed
    can [:create, :update], [ProjectSource, ProjectMedia], project: { team: { id: @teams }}
    can :destroy, [ProjectMedia, ProjectSource], project: { team: { id: @teams }}
    can [:create, :update, :destroy], [Source, Account], :team_id => @teams
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

end
