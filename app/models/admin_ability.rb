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
      owner_perms if @teams.any?
    end
  end

  private

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can [:read, :update, :delete_tasks], Team, id: @teams
    can [:index, :read, :update, :destroy, :export_project], Project, team_id: @teams
    can [:index, :read, :create, :update, :destroy], TeamBotInstallation, team_id: @teams
    can [:index, :read], BotUser, team_users: { team_id: @teams }
    can [:create, :update, :destroy], BotUser do |obj|
      @teams.include?(obj.team_author_id)
    end
    can :destroy, [ApiKey, Source], bot_user: { team_author_id: @teams }
    can [:install], BotUser do |obj|
      obj.get_approved
    end
    can :destroy, ProjectSource, project: { team_id: @teams }
    can :destroy, ProjectMedia do |obj|
      (obj.team ||= obj.project.team) if obj.project
      @teams.include?(obj.team.id) if obj.team
    end
    %w(annotation comment flag tag dynamic task).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        !(obj.get_team & @teams).empty?
      end
    end

    can :update, [Dynamic, Annotation], ['annotation_type = ?', 'metadata'] do |obj|
      !(obj.get_team & @teams).empty?
    end
    can :destroy, DynamicAnnotation::Field do |obj|
      !(obj.annotation.get_team & @teams).empty?
    end

    can :create, PaperTrail::Version

    Workflow::Workflow.workflows.each{ |w| instance_exec(&w.workflow_admin_permissions) if w.respond_to?(:workflow_admin_permissions) }
  end

end
