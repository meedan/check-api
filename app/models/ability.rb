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
      unless @api_key.nil?
        api_key_perms
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
    end
  end

  private

  def api_key_perms
    can :read, :all
  end

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can [:update, :destroy], User, :team_users => { :team_id => @context_team.id, role: ['owner', 'editor', 'journalist', 'contributor'] }
    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['owner']
    can :update, TeamUser, team_id: @context_team.id
    cannot :update, TeamUser, team_id: @context_team.id, user_id: @user.id
    can :destroy, Contact, :team_id => @context_team.id
    can :destroy, Project, :team_id => @context_team.id
    can :export_project, Project, team_id: @context_team.id
    can :destroy, [Media, Link, Claim] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :destroy, [ProjectMedia, ProjectSource], project: { team: { team_users: { team_id: @context_team.id }}}
    %w(annotation comment flag status tag embed dynamic task).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include? @context_team.id
      end
    end
    can :destroy, DynamicAnnotation::Field do |obj|
      obj.annotation.get_team.include? @context_team.id
    end
    can :destroy, PaperTrail::Version do |obj|
      teams = []
      v_obj = obj.item_type.constantize.find(obj.item_id)
      teams = v_obj.get_team if v_obj.respond_to?(:get_team)
      teams << v_obj.team_id if teams.blank? and v_obj.respond_to?(:team)
      teams << v_obj.project.team_id if teams.blank? and v_obj.respond_to?(:project)
      teams.include? @context_team.id
    end
  end

  def editor_perms
    can :update, User, :team_users => { :team_id => @context_team.id, role: ['editor'] }
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor']
    can :update, TeamUser, team_id: @context_team.id, role: ['editor', 'journalist', 'contributor']
    cannot :update, TeamUser, team_id: @context_team.id, user_id: @user.id
    can [:create, :update], Contact, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id
    can [:create, :update], ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}
    %w(annotation comment flag dynamic task).each do |annotation_type|
      can :update, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include? @context_team.id
      end
    end
    can :create, Task, ['annotation_type = ?', 'task'] do |task|
      task.get_team.include? @context_team.id
    end
  end

  def journalist_perms
    can :update, User, :team_users => { :team_id => @context_team.id, role: ['journalist', 'contributor'] }
    can :create, TeamUser, :team_id => @context_team.id, role: ['journalist', 'contributor']
    can :create, Project, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id, :user_id => @user.id
    can :update, [Media, Link, Claim], projects: { team: { team_users: { team_id: @context_team.id }}}
    can :update, ProjectMedia, project: { team: { team_users: { team_id: @context_team.id }}}
    can :create, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include? @context_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can :update, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include? @context_team.id and (flag.annotator_id.to_i == @user.id)
    end
    %w(status tag).each do |annotation_type|
      can :create, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include? @context_team.id
      end
    end
    can :update, Status, ['annotation_type = ?', 'status'] do |obj|
      obj.get_team.include? @context_team.id
    end
  end

  def contributor_perms
    can :update, User, :id => @user.id
    can :create, [Media, Account, Source, Comment, Embed, Link, Claim, Dynamic]
    can :update, [Media, Link, Claim], :user_id => @user.id
    can :update, [Media, Link, Claim] do |obj|
      obj.get_team.include? @context_team.id and (obj.user_id == @user.id)
    end
    can :update, [Account, Source, Embed]
    can [:create, :update], ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}, source: { user_id: @user.id }
    can :create, ProjectMedia, project: { team: { team_users: { team_id: @context_team.id }}}
    can [:update, :destroy], ProjectMedia, project: { team: { team_users: { team_id: @context_team.id }}}, media: { user_id: @user.id }
    can :update, Comment, ['annotation_type = ?', 'comment'] do |obj|
      obj.get_team.include? @context_team.id and (obj.annotator_id.to_i == @user.id)
    end
    can :create, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include? @context_team.id and (['Spam', 'Graphic content'].include?flag.flag.to_s)
    end
    can :create, Tag, ['annotation_type = ?', 'tag'] do |obj|
      (obj.get_team.include? @context_team.id and obj.annotated_type === 'ProjectMedia' and obj.annotated.user_id.to_i === @user.id) or obj.annotated_type === 'Source'
    end
    can :destroy, TeamUser, user_id: @user.id
    can :destroy, Tag, ['annotation_type = ?', 'tag'] do |obj|
      obj.get_team.include? @context_team.id
    end
    can [:destroy, :update], [Dynamic, Annotation, Task] do |obj|
      obj.annotator_id.to_i == @user.id
    end
    can [:create, :update, :destroy], DynamicAnnotation::Field do |obj|
      obj.annotation.annotator_id == @user.id
    end
    can :update, [Dynamic, Annotation] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :update, DynamicAnnotation::Field do |obj|
      obj.annotation.get_team.include? @context_team.id
    end

    can :update, Task, ['annotation_type = ?', 'task'] do |obj|
      before, after = obj.data_change
      changes = (after.to_a - before.to_a).to_h
      obj.get_team.include?(@context_team.id) && changes.keys == ['status']
    end
    can :destroy, PaperTrail::Version do |obj|
      v_obj = obj.item_type.constantize.find(obj.item_id) if obj.item_type == 'ProjectMedia'
      !v_obj.nil? and v_obj.project.team_id == @context_team.id and v_obj.media.user_id = @user.id
    end
  end
end
