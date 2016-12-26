class Ability
  include CanCan::Ability

  def initialize(user, context_team)
    alias_action :create, :update, :destroy, :to => :cud
    @user = user ||= User.new
    @context_team = context_team ||= @user.current_team
    # Define User abilities
    extra_perms_for_all_users
    if user.id
      authenticated_perms
    end
    if user.role? :contributor, context_team
      contributor_perms
    end
    if user.role? :journalist, context_team
      journalist_perms
    end
    if user.role? :editor, context_team
      editor_perms
    end
    if user.role? :owner, context_team
      owner_perms
    end
    if user.role? :admin, context_team
      global_admin_perms
    end
  end

  private

  def global_admin_perms
    can :manage, :all
  end

  def owner_perms
    can [:update, :destroy], User, :team_users => { :team_id => @context_team.id, role: ['owner', 'editor', 'journalist', 'contributor'] }
    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['owner']
    can :update, TeamUser do |obj|
      roles = %w[owner journalist contributor editor]
      user_role = obj.user.role @context_team
      obj.team_id == @context_team.id and obj.user_id != @user.id and roles.include? obj.role and (roles.include? user_role or user_role.nil?)
    end
    can :destroy, Contact, :team_id => @context_team.id
    can :destroy, Project, :team_id => @context_team.id
    can :destroy, Media do |obj|
      obj.get_team.include? @context_team.id
    end
    can :destroy, [ProjectMedia, ProjectSource] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :destroy, [Annotation, Comment, Tag, Status, Flag] do |obj|
      obj.get_team.include? @context_team.id
    end
  end

  def editor_perms
    can :update, User, :team_users => { :team_id => @context_team.id, role: ['editor'] }
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor']
    can :update, TeamUser do |obj|
      roles = %w[editor journalist contributor]
      user_role = obj.user.role @context_team
      obj.team_id == @context_team.id and obj.user_id != @user.id and roles.include? obj.role and (roles.include? user_role or user_role.nil?)
    end
    can [:create, :update], Contact, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id
    can [:create, :update], [ProjectMedia, ProjectSource] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :update, [Comment, Flag, Annotation] do |obj|
      obj.get_team.include? @context_team.id
    end
  end

  def journalist_perms
    can :update, User, :team_users => { :team_id => @context_team.id, role: ['journalist', 'contributor'] }
    can :create, TeamUser, :team_id => @context_team.id, role: ['journalist', 'contributor']
    can :create, Project, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id, :user_id => @user.id
    can :update, Media do |obj|
      obj.get_team.include? @context_team.id
    end
    can :create, Flag do |flag|
      flag.get_team.include? @context_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can :update, Flag do |flag|
      flag.get_team.include? @context_team.id and (flag.annotator_id.to_i == @user.id)
    end
    can :create, [Status, Tag] do |obj|
      obj.get_team.include? @context_team.id
    end
  end

  def contributor_perms
    can :update, User, :id => @user.id
    can :create, [Media, Account, Source, Comment, Embed]
    can :update, Media, :user_id => @user.id
    can :update, Media do |obj|
      obj.get_team.include? @context_team.id and (obj.user_id == @user.id)
    end
    can :update, [Account, Source]
    can [:create, :update], ProjectSource do |obj|
      obj.get_team.include? @context_team.id and (obj.source.user_id == @user.id)
    end
    can :create, ProjectMedia do |obj|
      obj.get_team.include? @context_team.id
    end
    can :update, ProjectMedia do |obj|
      obj.get_team.include? @context_team.id and (obj.media.user_id == @user.id)
    end
    can :update, Comment do |obj|
      obj.get_team.include? @context_team.id and (obj.annotator_id.to_i == @user.id)
    end
    can :create, Flag do |flag|
      flag.get_team.include? @context_team.id and (['Spam', 'Graphic content'].include?flag.flag.to_s)
    end
    can :create, Tag do |obj|
      (obj.get_team.include? @context_team.id and obj.annotated_type === 'ProjectMedia' and obj.annotated.user_id.to_i === @user.id) or obj.annotated_type === 'ProjectSource'
    end
    can :destroy, TeamUser do |obj|
      obj.user_id === @user.id
    end
    can :destroy, Tag do |obj|
      obj.get_team.include? @context_team.id
    end
  end

  def authenticated_perms
    can :create, Team
    can :create, TeamUser, :user_id => @user.id, status: ['member', 'requested']
  end

  # Extra permissions for all users
  def extra_perms_for_all_users
    can :create, User
    can :read, Team, :private => false
    can :read, Team, :private => true, :team_users => { :user_id => @user.id, :status => 'member' }

    # A @user can read a user if:
    # 1) @user is the same as target user
    # 2) target user is a member of at least one public team
    # 3) @user is a member of at least one same team as the target user
    can :read, User do |obj|
      @user.id == obj.id || obj.teams.where('teams.private' => false).exists? || @user.is_a_colleague_of?(obj)
    end

    # A @user can read contact, project or team user if:
    # 1) team is private and @user is a member of that team
    # 2) team user is not private
    can :read, [Contact, Project, TeamUser] do |obj|
      team = obj.team
      !team.private || @user.is_member_of?(team)
    end

    # A @user can read any of those objects if:
    # 1) it's a source related to him/her or not related to any user
    # 2) it's related to at least one public team
    # 3) it's related to a private team which the @user has access to
    can :read, [Account, Source, Media, ProjectMedia, ProjectSource, Comment, Flag, Status, Tag, Embed] do |obj|
      if obj.is_a?(Source) && obj.respond_to?(:user_id)
        obj.user_id == @user.id || obj.user_id.nil?
      else
        team_ids = obj.get_team
        teams = obj.respond_to?(:get_team_objects) ? obj.get_team_objects.reject{ |t| t.private } : Team.where(id: team_ids, private: false)
        if teams.empty?
          TeamUser.where(user_id: @user.id, team_id: team_ids, status: 'member').exists?
        else
          teams.any?
        end
      end
    end
  end
end
