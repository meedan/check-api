class Ability
  include CheckBasicAbilities

  def initialize(user = nil)
    alias_action :create, :update, :destroy, :to => :cud
    @user = User.current ||= user || User.new
    @api_key = ApiKey.current
    @context_team = Team.current ||= @user.current_team
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
      if @user.role? :contributor
        contributor_perms
      end
      if @user.role? :journalist
        journalist_perms
      end
      if @user.role? :editor
        editor_perms
      end
      if @user.role? :owner
        owner_perms
      end
      unless @api_key.nil?
        api_key_perms
      end
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
  end

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can :destroy, :trash

    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['owner']
    can :update, TeamUser, team_id: @context_team.id
    cannot :update, TeamUser, team_id: @context_team.id, user_id: @user.id
    can :destroy, Contact, :team_id => @context_team.id
    can :destroy, Project, :team_id => @context_team.id
    can :export_project, Project, team_id: @context_team.id
    can :destroy, [Media, Link, Claim] do |obj|
      obj.get_team.include?(@context_team.id)
    end
    can :destroy, ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}
    can :destroy, TeamSource, :team_id => @context_team.id
    can :destroy, ProjectMedia do |obj|
      obj.related_to_team?(@context_team)
    end
    can :destroy, Account, team_id: @context_team.id
    can :destroy, AccountSource, account: { team: { team_users: { team_id: @context_team.id }}}
    %w(annotation comment flag status tag embed dynamic task source_identity).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include?(@context_team.id)
      end
    end
    can :destroy, DynamicAnnotation::Field do |obj|
      obj.annotation.get_team.include?(@context_team.id)
    end
    can :destroy, PaperTrail::Version do |obj|
      teams = []
      v_obj = begin
                obj.item_type.constantize.find(obj.item_id)
              rescue
                nil
              end
      v_obj_parent = begin
                       obj.associated_type.constantize.find(obj.associated_id)
                     rescue
                       nil
                     end
      if v_obj
        teams = v_obj.get_team if v_obj.respond_to?(:get_team)
        teams << v_obj.team_id if teams.blank? and v_obj.respond_to?(:team)
        teams << v_obj.project.team_id if teams.blank? and v_obj.respond_to?(:project)
      end
      teams << v_obj_parent.project.team_id if v_obj_parent and v_obj_parent.respond_to?(:project)
      teams.include?(@context_team.id)
    end
  end

  def editor_perms
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor']
    can :update, TeamUser, team_id: @context_team.id, role: ['editor', 'journalist', 'contributor'], role_was: ['editor', 'journalist', 'contributor']
    cannot :update, TeamUser, team_id: @context_team.id, user_id: @user.id
    can [:create, :update], Contact, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id
    can :destroy, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false && obj.user_id == @user.id
    end
    %w(annotation comment flag dynamic task).each do |annotation_type|
      can :update, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include?(@context_team.id) && obj.user_id == @user.id && !obj.annotated_is_archived?
      end
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived?
      end
    end
    can :create, Task, ['annotation_type = ?', 'task'] do |task|
      task.get_team.include?(@context_team.id) && !task.annotated_is_archived?
    end
  end

  def journalist_perms
    can :create, TeamUser, :team_id => @context_team.id, role: ['journalist', 'contributor']
    can :create, Project, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id, :user_id => @user.id
    can :update, [Media, Link, Claim], projects: { team: { team_users: { team_id: @context_team.id }}}
    can :update, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false
    end
    can [:create, :update], ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}
    can [:create, :update], [TeamSource, Account], team: { team_users: { team_id: @context_team.id }}
    can [:create, :update], AccountSource, account: { team: { team_users: { team_id: @context_team.id }}}
    can :create, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include?(@context_team.id) and (flag.flag.to_s == 'Mark as graphic') and !flag.annotated_is_archived?
    end
    can :update, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include?(@context_team.id) and (flag.annotator_id.to_i == @user.id) and !flag.annotated_is_archived?
    end
    %w(status tag).each do |annotation_type|
      can :create, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived?
      end
    end
    can :update, Status, ['annotation_type = ?', 'status'] do |obj|
      obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived?
    end
    %w(annotation comment).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.annotation_type == 'comment' && obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived?
      end
    end
  end

  def contributor_perms
    can :update, User, :id => @user.id
    can :create, [Media, Embed, Link, Claim, SourceIdentity]
    %w(comment dynamic).each do |annotation_type|
      can :create, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        ((obj.get_team & @user.cached_teams).any? || (obj.annotated.present? && obj.annotated.user_id.to_i == @user.id)) && !obj.annotated_is_archived?
      end
    end
    can :update, [Media, Link, Claim], { user_id: @user.id }
    can :update, [Media, Link, Claim] do |obj|
      obj.get_team.include?(@context_team.id) and (obj.user_id == @user.id)
    end
    can :update, [Embed, SourceIdentity]
    can [:create, :update], ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}, source: { user_id: @user.id }
    can [:create, :update], [Account, TeamSource], team: { team_users: { team_id: @context_team.id }}
    can :create, Source
    can [:create, :update], AccountSource, account: { user_id: @user.id, team: { team_users: { team_id: @context_team.id }}}
    can :create, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false
    end
    can :update, ProjectMedia do |obj|
      obj.related_to_team?(@context_team) && obj.archived_was == false && obj.user_id == @user.id
    end
    can [:update, :destroy], Comment, ['annotation_type = ?', 'comment'] do |obj|
      obj.get_team.include?(@context_team.id) and (obj.annotator_id.to_i == @user.id) and !obj.annotated_is_archived?
    end
    can :create, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include?(@context_team.id) and (['Spam', 'Graphic content'].include?(flag.flag.to_s)) and !flag.annotated_is_archived?
    end
    can :create, Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.get_team.include?(@context_team.id) and (obj.annotated.user_id.to_i === @user.id) and !obj.annotated_is_archived?
    end
    can :destroy, TeamUser, user_id: @user.id
    can :destroy, Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.get_team.include?(@context_team.id) and !obj.annotated_is_archived?
    end
    can [:destroy, :update], [Dynamic, Annotation, Task] do |obj|
      obj.annotator_id.to_i == @user.id and !obj.annotated_is_archived?
    end
    can [:create, :update, :destroy], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id == @user.id and !obj.annotation.annotated_is_archived?
    end
    can :update, [Dynamic, Annotation] do |obj|
      obj.get_team.include?(@context_team.id) and !obj.annotated_is_archived?
    end
    can :update, DynamicAnnotation::Field do |obj|
      obj.annotation.get_team.include?(@context_team.id) and !obj.annotation.annotated_is_archived?
    end

    can :update, Task, ['annotation_type = ?', 'task'] do |obj|
      before, after = obj.data_change
      changes = (after.to_a - before.to_a).to_h
      obj.get_team.include?(@context_team.id) && changes.keys == ['status'] && !obj.annotated_is_archived?
    end
    can :destroy, PaperTrail::Version do |obj|
      v_obj = obj.item_type.constantize.find(obj.item_id) if obj.item_type == 'ProjectMedia'
      !v_obj.nil? and v_obj.project.team_id == @context_team.id and v_obj.media.user_id = @user.id
    end
  end
end
