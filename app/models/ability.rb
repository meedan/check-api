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
    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['admin']
    can [:update, :destroy], TeamUser, team_id: @context_team.id
    can [:duplicate, :export_list], Team, :id => @context_team.id
    can :set_privacy, Project, :team_id => @context_team.id
    can :read_feed_invitations, Feed, :team_id => @context_team.id
    can :destroy, Feed, :team_id => @context_team.id
    can [:create, :update], FeedTeam, :team_id => @context_team.id
    can [:create, :update], FeedInvitation, { feed: { team_id: @context_team.id } }
    can :destroy, FeedTeam do |obj|
      obj.team_id == @context_team.id || obj.feed.team_id == @context_team.id
    end
    can [:create, :update, :read, :destroy], ApiKey, :team_id => @context_team.id
    can :destroy, [Dynamic, DynamicAnnotation::Field], annotation_type: 'metadata' # FIXME: Restrict by team
  end

  def editor_perms
    can :destroy, :trash
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor', 'collaborator']
    can :update, TeamUser, team_id: @context_team.id, role: ['editor', 'collaborator'], role_was: ['editor', 'collaborator']
    can :preview_rss_feed, Team, :id => @context_team.id
    can :invite_members, Team, :id => @context_team.id
    can [:create, :update], Project, :team_id => @context_team.id
    can :destroy, Project do |obj|
      obj.team_id == @context_team.id && !obj.is_default?
    end
    can :destroy, ProjectMedia do |obj|
      obj.related_to_team?(@context_team)
    end
    can :manage, [TagText, TeamTask], team_id: @context_team.id
    can [:bulk_create], Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.team == @context_team
    end
    can [:cud], [SavedSearch, ProjectGroup], :team_id => @context_team.id
    can [:cud], DynamicAnnotation::Field do |obj|
      obj.annotation.team&.id == @context_team.id
    end
    can [:create, :update, :read, :destroy], [Account, Source, TiplineNewsletter, TiplineResource, TiplineRequest], :team_id => @context_team.id
    can [:cud], AccountSource, source: { team: { team_users: { team_id: @context_team.id }}}
    %w(annotation dynamic task tag).each do |annotation_type|
      can [:cud], annotation_type.classify.constantize do |obj|
        obj.team&.id == @context_team.id
      end
    end
    can :destroy, Version do |obj|
      teams = []
      v_obj = begin obj.item_type.constantize.find(obj.item_id) rescue nil end
      v_obj_parent = begin obj.associated_type.constantize.find(obj.associated_id) rescue nil end
      teams << v_obj.team&.id if v_obj
      teams << v_obj_parent.team&.id if v_obj_parent
      teams.include?(@context_team.id)
    end
    can :send, TiplineMessage do |obj|
      obj.team_id == @context_team.id
    end
    can [:read], FeedTeam, :team_id => @context_team.id
    can [:read], FeedInvitation, { feed: { team_id: @context_team.id } }
    can [:read, :create, :update, :import_media], Feed, :team_id => @context_team.id
    can :import_media, Feed do |obj|
      obj.team_ids.include?(@context_team.id)
    end
  end

  def collaborator_perms
    can [:cud, :bulk_update, :bulk_destroy], Relationship, { source: { team_id: @context_team.id }, target: { team_id: @context_team.id } }
    can [:create, :update], ProjectMedia do |obj|
      obj.related_to_team?(@context_team) || TeamUser.where(user_id: @user.id, status: 'member', team_id: obj.team_id).exists?
    end
    can :create, [Media, Link, Claim]
    can :update, [Media, Link, Claim], { user_id: @user.id }
    can [:update, :destroy], [Media, Link, Claim] do |obj|
      obj.team_ids.include?(@context_team.id)
    end
    can :destroy, TeamUser, user_id: @user.id
    can :lock_annotation, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == CheckArchivedFlags::FlagCodes::NONE
    end
    can :create, Source, :team_id => @context_team.id
    can [:create, :update], Account, source: { team: { team_users: { team_id: @context_team.id }}}, :user_id => @user.id
    can [:create, :update], AccountSource, source: { user_id: @user.id, team: { team_users: { team_id: @context_team.id }}}
    can [:create, :update], [Dynamic, Annotation], { annotation_type: 'metadata' }
    %w(annotation dynamic task tag).each do |annotation_type|
      can [:cud], annotation_type.classify.constantize do |obj|
        obj.team&.id == @context_team.id && !obj.annotated_is_trashed?
      end
    end
    can [:cud], TiplineRequest do |obj|
      is_trashed = obj.associated.respond_to?(:archived) && obj.associated.archived == CheckArchivedFlags::FlagCodes::TRASHED
      obj.team_id == @context_team.id && !is_trashed
    end
    can [:create, :destroy], Assignment do |obj|
      type = obj.assigned_type
      obj = obj.assigned
      obj.team&.id == @context_team.id && ((type == 'Annotation' && !obj.annotated_is_trashed?) || (type == 'Project' && obj.archived == CheckArchivedFlags::FlagCodes::NONE))
    end
    can [:cud], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id == @user.id and !obj.annotation.annotated_is_archived?
    end
    can [:cud], DynamicAnnotation::Field do |obj|
      obj.annotation.team&.id == @context_team.id and !obj.annotation.annotated_is_trashed?
    end
    can :update, Task, ['annotation_type = ?', 'task'] do |obj|
      before, after = obj.data_change
      changes = (after.to_a - before.to_a).to_h
      obj.team&.id == @context_team.id && changes.keys == [] && !obj.annotated_is_trashed?
    end
    can [:administer_content, :bulk_update, :bulk_mark_read], ProjectMedia do |obj|
      obj.related_to_team?(@context_team)
    end
    can [:destroy, :update], [Dynamic, Annotation] do |obj|
      obj.annotator_id.to_i == @user.id and !obj.annotated_is_archived?
    end
    can :destroy, Version do |obj|
      v_obj = obj.item_type.constantize.find(obj.item_id) if obj.item_type == 'ProjectMedia'
      !v_obj.nil? and v_obj.team_id == @context_team.id and v_obj.media.user_id = @user.id
    end
    can [:create, :update, :read, :destroy], FactCheck, { claim_description: { team_id: @context_team.id } }
    can [:create, :update, :read, :destroy], Explainer, team_id: @context_team.id
    can [:create, :update, :read], ClaimDescription, { team_id: @context_team.id }
    can [:create, :update, :read, :destroy], ExplainerItem, { project_media: { team_id: @context_team.id } }
  end

  def bot_permissions
    # Bots are usually out of a team context, so we need to check based on the attribute values
    can [:cud], BotUser do |obj|
      is_owner_of_bot_team(obj.team_author_id)
    end
    can [:cud], TeamBotInstallation do |obj|
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
