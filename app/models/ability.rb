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
      if @user.role?(:collaborator, @context_team)
        collaborator_perms
      end
      if @user.role?(:editor, @context_team)
        editor_perms
      end
      if @user.role?(:admin, @context_team)
        admin_perms
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

  def admin_perms
    can :destroy, :trash
    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['admin']
    can :update, TeamUser, team_id: @context_team.id
    can :preview_rss_feed, Team, :id => @context_team.id
    can :manage, [TagText, TeamTask], team_id: @context_team.id
    can :duplicate, Team, :id => @context_team.id
  end

  def editor_perms
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor', 'collaborator']
    can :update, TeamUser, team_id: @context_team.id, role: ['editor', 'collaborator'], role_was: ['editor', 'collaborator']
    can [:create, :update, :destroy], Contact, :team_id => @context_team.id
    can :import_spreadsheet, Team, :id => @context_team.id
    can :invite_members, Team, :id => @context_team.id
    can [:bulk_create], Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.team == @context_team
    end
    can [:bulk_create, :bulk_update, :bulk_destroy], ProjectMediaProject do |obj|
      obj.team == @context_team
    end
    can :lock_annotation, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == CheckArchivedFlags::FlagCodes::NONE
    end
    can [:administer_content, :bulk_update], ProjectMedia do |obj|
      obj.related_to_team?(@context_team)
    end
    can [:create, :update, :destroy], BotResource, :team_id => @context_team.id
    can [:create, :update, :destroy], DynamicAnnotation::Field do |obj|
      obj.annotation.team&.id == @context_team.id and !obj.annotation.annotated_is_trashed?
    end
    can [:create, :update, :destroy], [Account, Source], :team_id => @context_team.id
    can [:create, :update, :destroy], AccountSource, source: { team: { team_users: { team_id: @context_team.id }}}
  end

  def collaborator_perms
    can [:create, :update, :destroy], Project, :team_id => @context_team.id
    can [:create, :update, :destroy], Relationship, { source: { team_id: @context_team.id }, target: { team_id: @context_team.id } }
    can [:create, :update, :destroy ], ProjectMedia do |obj|
      obj.related_to_team?(@context_team)
    end
    can :create, [Media, Link, Claim]
    can [:update, :destroy], [Media, Link, Claim] do |obj|
      obj.team_ids.include?(@context_team.id)
    end
    can [:create, :update, :destroy], ProjectMediaProject do |obj|
      obj.project && obj.project.team_id == @context_team.id
    end
    can :destroy, TeamUser, user_id: @user.id
    %w(annotation comment dynamic task tag).each do |annotation_type|
      can [:create, :update, :destroy], annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.team&.id == @context_team.id && !obj.annotated_is_trashed?
      end
    end
    can [:create, :update], [Dynamic, Annotation], { annotation_type: 'metadata' }
    can [:create, :destroy], Assignment do |obj|
      type = obj.assigned_type
      obj = obj.assigned
      obj.team&.id == @context_team.id && ((type == 'Annotation' && !obj.annotated_is_trashed?) || (type == 'Project' && obj.archived == CheckArchivedFlags::FlagCodes::NONE))
    end
    can [:create, :update, :destroy], DynamicAnnotation::Field do |obj|
      obj.annotation.team&.id == @context_team.id and !obj.annotation.annotated_is_trashed?
    end
    can :destroy, Version do |obj|
      teams = []
      v_obj = begin obj.item_type.constantize.find(obj.item_id) rescue nil end
      v_obj_parent = begin obj.associated_type.constantize.find(obj.associated_id) rescue nil end
      teams << v_obj.team&.id if v_obj
      teams << v_obj_parent.team&.id if v_obj_parent
      teams.include?(@context_team.id)
    end
    can :update, Task, ['annotation_type = ?', 'task'] do |obj|
      before, after = obj.data_change
      changes = (after.to_a - before.to_a).to_h
      obj.team&.id == @context_team.id && changes.keys == [] && !obj.annotated_is_trashed?
    end
    cannot :bulk_update, ProjectMedia
    cannot [:read, :manage], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id != @user.id
    end
    can [:read, :manage], DynamicAnnotation::Field, annotation: { annotator_id: @user.id }
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
    !TeamUser.where(user_id: @user.id, team_id: team_id, role: 'admin').last.nil?
  end
end
