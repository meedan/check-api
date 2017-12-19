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

    can [:read, :update], Team, id: @teams
    can [:index, :destroy, :export_project], Project, team_id: @teams
    can :destroy, ProjectSource, project: { team_id: @teams }
    can :destroy, ProjectMedia do |obj|
      (obj.team ||= obj.project.team) if obj.project
      @teams.include?(obj.team.id) if obj.team
    end
    %w(comment dynamic flag tag task).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        !(obj.get_team && @teams).empty?
      end
    end
    %w(embed status).each do |annotation_type|
      can :update, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        !(obj.get_team && @teams).empty?
      end
    end
    can :destroy, DynamicAnnotation::Field do |obj|
      !(obj.annotation.get_team && @teams).empty?
    end

    can :create, PaperTrail::Version
  end

end
