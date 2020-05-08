class Ability
  include CheckBasicAbilities

  def initialize(user = nil, team = nil)
    alias_action :create, :update, :destroy, :to => :cud
    @user = User.current ||= user || User.new
    @api_key = ApiKey.current
    Team.current ||= (@user.current_team || Team.new)
    @context_team = team || Team.current
    # Define User abilities
    if @user.is_admin?
      global_admin_perms
    else
      extra_perms_for_all_users
      if !@api_key.nil? && !@user.id
        global_api_key_perms
      end
      if @user.id
        authenticated_perms
      end
      if @user.role?(:annotator, @context_team)
        annotator_perms
      end
      if @user.role?(:contributor, @context_team)
        contributor_perms
      end
      if @user.role?(:journalist, @context_team)
        journalist_perms
      end
      if @user.role?(:editor, @context_team)
        editor_perms
      end
      if @user.role?(:owner, @context_team)
        owner_perms
      end
      unless @api_key.nil?
        api_key_perms
      end
      Workflow::Workflow.workflows.each do |w|
        instance_exec(&w.workflow_permissions) if w.respond_to?(:workflow_permissions)
      end
      bot_permissions
    end
  end

  private

  def api_key_perms
    cannot [:create, :destroy], Team
    cannot :cud, User
    cannot :cud, TeamUser
    can :update, User, :id => @user.id
    can :update, BotUser, :id => @user.id
  end

  def global_api_key_perms
    can :read, :all
    can :find_by_json_fields, DynamicAnnotation::Field
    can :update, [Dynamic, DynamicAnnotation::Field], annotation_type: 'smooch_user'
  end

  def annotator_perms
    cannot [:read, :manage], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id != @user.id
    end
    can [:read, :manage], DynamicAnnotation::Field, annotation: { annotator_id: @user.id }
    can [:update, :destroy], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id == @user.id and !obj.annotation.annotated_is_archived?
    end

    assignments = @user.cached_assignments
    pids = assignments[:pids]
    pmids = assignments[:pmids]

    cannot :read, [User, ProjectMedia, Project, Task]
    can :read, User, id: @user.id
    can :read, ProjectMedia, id: pmids
    can :read, Project, id: pids
    can :read, Task do |task|
      task.assigned_users.include?(@user)
    end

    can_list [TeamUser, Assignment], user_id: @user.id
    can_list Version, whodunnit: @user.id.to_s
    can_list User, id: @user.id
    can_list Task, { 'joins' => :assignments, 'assignments.user_id' => @user.id }
    can_list ProjectMedia, id: pmids
    can_list Project, id: pids
    can_list [Annotation, Dynamic], { annotator_id: @user.id }

    contributor_and_annotator_perms
  end

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can :destroy, :trash

    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['owner']
    can :update, TeamUser, team_id: @context_team.id
    can :destroy, Contact, :team_id => @context_team.id
    can :destroy, Project, :team_id => @context_team.id
    can :export_project, Project, team_id: @context_team.id
    can :destroy, [Media, Link, Claim] do |obj|
      obj.get_team.include?(@context_team.id)
    end
    can :destroy, ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}
    can :destroy, ProjectMedia do |obj|
      obj.related_to_team?(@context_team)
    end
    can :destroy, Source, :team_id => @context_team.id
    can :destroy, [Account, AccountSource], source: { team: { team_users: { team_id: @context_team.id }}}
    %w(annotation comment tag dynamic task).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize do |obj|
        obj.get_team.include?(@context_team.id)
      end
    end
    can :destroy, DynamicAnnotation::Field do |obj|
      obj.annotation.get_team.include?(@context_team.id)
    end
    can :destroy, Version do |obj|
      teams = []
      v_obj = begin obj.item_type.constantize.find(obj.item_id) rescue nil end
      v_obj_parent = begin obj.associated_type.constantize.find(obj.associated_id) rescue nil end
      if v_obj
        teams = v_obj.get_team if v_obj.respond_to?(:get_team)
        teams << v_obj.team_id if teams.blank? and v_obj.respond_to?(:team)
        teams << v_obj.project.team_id if teams.blank? and v_obj.respond_to?(:project)
      end
      teams << v_obj_parent.project.team_id if v_obj_parent and v_obj_parent.respond_to?(:project)
      teams.include?(@context_team.id)
    end
    can :manage, [TagText, TeamTask], team_id: @context_team.id
    can :import_spreadsheet, Team, :id => @context_team.id
  end

  def editor_perms
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor', 'annotator']
    can :update, TeamUser, team_id: @context_team.id, role: ['editor', 'journalist', 'contributor'], role_was: ['editor', 'journalist', 'contributor']
    can [:create, :update], Contact, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id
    can [:update, :destroy], Relationship, { source: { team_id: @context_team.id }, target: { team_id: @context_team.id } }
    can :destroy, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false && obj.user_id == @user.id
    end
    %w(annotation comment dynamic task).each do |annotation_type|
      can [:destroy, :update], annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived?
      end
    end
    can [:destroy, :create], Assignment do |obj|
      type = obj.assigned_type
      obj = obj.assigned
      obj.get_team.include?(@context_team.id) && ((type == 'Annotation' && !obj.annotated_is_archived?) || (type == 'Project' && !obj.archived))
    end
    can :lock_annotation, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false
    end
    can :import_spreadsheet, Team, :id => @context_team.id
    can :invite_members, Team, :id => @context_team.id
  end

  def journalist_perms
    can :create, TeamUser, :team_id => @context_team.id, role: ['journalist', 'contributor']
    can :create, Project, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id, :user_id => @user.id
    can :update, [Media, Link, Claim], projects: { team: { team_users: { team_id: @context_team.id }}}
    can [:update, :administer_content], ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false
    end
    can [:create, :update], ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}
    can [:create, :update], Source, :team_id => @context_team.id
    can [:create, :destroy], Relationship, { user_id: @user.id, source: { team_id: @context_team.id }, target: { team_id: @context_team.id } }
    can [:create, :update], [Account, AccountSource], source: { team: { team_users: { team_id: @context_team.id }}}
    can [:create, :update], Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived?
    end
    %w(annotation comment).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.annotation_type == 'comment' && obj.user_id == @user.id && obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived? && !obj.locked?
      end
    end
    can :create, Task, ['annotation_type = ?', 'task'] do |task|
      task.get_team.include?(@context_team.id) && !task.annotated_is_archived?
    end
  end

  def contributor_perms
    can :create, [Media, Link, Claim]
    can [:create, :update], [Dynamic, Annotation], { annotation_type: 'metadata' }
    can :update, [Media, Link, Claim], { user_id: @user.id }
    can :update, [Media, Link, Claim] do |obj|
      obj.get_team.include?(@context_team.id) and (obj.user_id == @user.id)
    end
    can [:create, :update], ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}, source: { user_id: @user.id }
    can [:create, :update], Source do |obj|
      obj.team_id == @context_team.id && obj.user_id == @user.id
    end
    can [:create, :update], Account, source: { team: { team_users: { team_id: @context_team.id }}}, :user_id => @user.id
    can [:create, :update], AccountSource, source: { user_id: @user.id, team: { team_users: { team_id: @context_team.id }}}
    can :create, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false
    end
    can :update, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false && obj.user_id == @user.id
    end
    can [:update, :destroy], Comment, ['annotation_type = ?', 'comment'] do |obj|
      obj.get_team.include?(@context_team.id) and (obj.annotator_id.to_i == @user.id) and !obj.annotated_is_archived? && !obj.locked?
    end
    can :create, Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.get_team.include?(@context_team.id) and (obj.annotated.user_id.to_i === @user.id) and !obj.annotated_is_archived?
    end
    can :destroy, TeamUser, user_id: @user.id
    can :destroy, Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.get_team.include?(@context_team.id) and !obj.annotated_is_archived?
    end
    can [:destroy, :update], [Dynamic, Annotation, Task] do |obj|
      obj.annotator_id.to_i == @user.id and !obj.annotated_is_archived? and !obj.locked?
    end
    can [:destroy, :create], Assignment do |obj|
      type = obj.assigned_type
      obj = obj.assigned
      (type == 'Annotation' && obj.annotator_id.to_i == @user.id && !obj.annotated_is_archived? && !obj.locked?) || (type == 'Project' && obj.user_id == @user.id && !obj.archived)
    end
    can [:create, :update, :destroy], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id == @user.id and !obj.annotation.annotated_is_archived?
    end
    can :update, DynamicAnnotation::Field do |obj|
      obj.annotation.get_team.include?(@context_team.id) and !obj.annotation.annotated_is_archived?
    end
    can :destroy, Version do |obj|
      v_obj = obj.item_type.constantize.find(obj.item_id) if obj.item_type == 'ProjectMedia'
      !v_obj.nil? and v_obj.project.team_id == @context_team.id and v_obj.media.user_id = @user.id
    end
    contributor_and_annotator_perms
  end

  def contributor_and_annotator_perms
    can :update, Task, ['annotation_type = ?', 'task'] do |obj|
      before, after = obj.data_change
      changes = (after.to_a - before.to_a).to_h
      obj.get_team.include?(@context_team.id) && changes.keys == [] && !obj.annotated_is_archived?
    end
    %w(comment dynamic).each do |annotation_type|
      can :create, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        ((obj.get_team & @user.cached_teams).any? || (obj.annotated.present? && obj.annotated.user_id.to_i == @user.id)) && !obj.annotated_is_archived?
      end
    end
    can :update, [Dynamic, Annotation] do |obj|
      obj.get_team.include?(@context_team.id) and !obj.annotated_is_archived? and !obj.locked? and obj.annotator_id == @user.id
    end
    can [:create, :destroy], ProjectMediaProject do |obj|
      obj.project && obj.project.team_id == @context_team.id
    end
  end

  def bot_permissions
    # Bots are usually out of a team context, so we need to check based on the attribute values
    can [:create, :update, :destroy], BotUser do |obj|
      is_owner_of_bot_team(obj.team_author_id)
    end
    can [:create, :update, :destroy], TeamBotInstallation do |obj|
      is_owner_of_bot_team(obj.team_id)
    end
    can :destroy, BotUser do |obj|
      is_owner_of_bot_team(obj&.team_author_id)
    end
    can :destroy, [ApiKey, Source] do |obj|
      is_owner_of_bot_team(obj&.bot_user&.team_author_id)
    end
  end

  def is_owner_of_bot_team(team_id)
    return false if team_id.blank?
    !TeamUser.where(user_id: @user.id, team_id: team_id, role: 'owner').last.nil?
  end
end
