class Ability
  include CanCan::Ability

  def initialize(user = nil)
    alias_action :create, :update, :destroy, :to => :cud
    @user = User.current ||= user || User.new
    @context_team = Team.current ||= @user.current_team
    # Define User abilities
    extra_perms_for_all_users
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
    if @user.role? :admin
      global_admin_perms
    end
  end

  private

  def global_admin_perms
    can :access, :rails_admin
    can :dashboard
    can :manage, :all
  end

  def owner_perms
    can [:update, :destroy], User, :team_users => { :team_id => @context_team.id, role: ['owner', 'editor', 'journalist', 'contributor'] }
    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['owner']
    can :update, TeamUser do |obj|
      roles = %w[owner journalist contributor editor]
      user_role = obj.user.role
      obj.team_id == @context_team.id and obj.user_id != @user.id and roles.include? obj.role and (roles.include? user_role or user_role.nil?)
    end
    can :destroy, Contact, :team_id => @context_team.id
    can :destroy, Project, :team_id => @context_team.id
    can :destroy, [Media, Link, Claim] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :destroy, [ProjectMedia, ProjectSource] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :destroy, [Annotation, Comment, Tag, Status, Flag] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :destroy, PaperTrail::Version do |obj|
      s = nil
      s = Status.where(id: obj.item_id).last if obj.item_type ==  'Status'
      !s.nil? and s.get_team.include? @context_team.id
    end
  end

  def editor_perms
    can :update, User, :team_users => { :team_id => @context_team.id, role: ['editor'] }
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor']
    can :update, TeamUser do |obj|
      roles = %w[editor journalist contributor]
      user_role = obj.user.role
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
    can :update, [Media, Claim, Link] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :create, Flag do |flag|
      flag.get_team.include? @context_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can :update, Flag do |flag|
      flag.get_team.include? @context_team.id and (flag.annotator_id.to_i == @user.id)
    end
    can :create, Tag do |obj|
      obj.get_team.include? @context_team.id
    end
    can [:create, :update], Status do |obj|
      obj.get_team.include? @context_team.id
    end
  end

  def contributor_perms
    can :update, User, :id => @user.id
    can :create, [Media, Account, Source, Comment, Embed, Link, Claim]
    can :update, [Media, Link, Claim], :user_id => @user.id
    can :update, [Media, Link, Claim] do |obj|
      obj.get_team.include? @context_team.id and (obj.user_id == @user.id)
    end
    can :update, [Account, Source, Embed]
    can [:create, :update], ProjectSource do |obj|
      obj.get_team.include? @context_team.id and (obj.source.user_id == @user.id)
    end
    can :create, ProjectMedia do |obj|
      obj.get_team.include? @context_team.id
    end
    can [:update, :destroy], ProjectMedia do |obj|
      obj.get_team.include? @context_team.id and (obj.media.user_id == @user.id)
    end
    can :update, Comment do |obj|
      obj.get_team.include? @context_team.id and (obj.annotator_id.to_i == @user.id)
    end
    can :create, Flag do |flag|
      flag.get_team.include? @context_team.id and (['Spam', 'Graphic content'].include?flag.flag.to_s)
    end
    can :create, Tag do |obj|
      (obj.get_team.include? @context_team.id and obj.annotated_type === 'ProjectMedia' and obj.annotated.user_id.to_i === @user.id) or obj.annotated_type === 'Source'
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

    # Permissions for registration and login
    can :create, Source, :user_id => @user.id
    can :update, User, :id => @user.id
    can :create, Account, :user_id => @user.id
    can :create, Embed, :annotated_id => @user.account_ids
  end

  # Extra permissions for all users
  def extra_perms_for_all_users
    can :access, :rails_admin
    can :dashboard

    can :create, User
    can :create, PaperTrail::Version
    can :read, Team, :private => false
    can :read, Team, :private => true, :team_users => { :user_id => @user.id, :status => 'member' }

    # A @user can read a user if:
    # 1) @user is the same as target user
    # 2) target user is a member of at least one public team
    # 3) @user is a member of at least one same team as the target user
    can :read, User, id: @user.id
    can :read, User, :teams => { :private => false }
    can :read, User, team_users: { team_id: @user.teams.map(&:id) }

    # A @user can read contact, project or team user if:
    # 1) team is private and @user is a member of that team
    # 2) team user is not private
    can :read, [Contact, Project, TeamUser], :team => { :id => @user.teams.map(&:id) }
    can :read, [Contact, Project, TeamUser], :team => { :private => false }

    # A @user can read any of those objects if:
    # 1) it's a source related to him/her or not related to any user
    # 2) it's related to at least one public team
    # 3) it's related to a private team which the @user has access to

    can :read, Account, :source => { :projects => { :team => { :id => @user.teams.map(&:id), :private => false }}}
    can :read, Account, :source => { :projects => { :team => { :team_users => { :team_id => @user.teams.map(&:id), :user_id => @user.id, :status => 'member' }}}}

    can :read, Source, :user => { :id => [@user.id, nil] }
    can :read, [Source, Media, Link, Claim], :projects => { :team => { :id => @user.teams.map(&:id), :private => false }}
    can :read, [Source, Media, Link, Claim], :projects => { :team => { :team_users => { :team_id => @user.teams.map(&:id), :user_id => @user.id, :status => 'member' }}}

    can :read, [ProjectMedia, ProjectSource], :project => { :team => { :id => @user.teams.map(&:id), :private => false }}
    can :read, [ProjectMedia, ProjectSource], :project => { :team => { :team_users => { :team_id => @user.teams.map(&:id), :user_id => @user.id, :status => 'member' }}}

    can :read, [Comment, Flag, Status, Tag, Embed] do |obj|
      team_ids = obj.get_team
      teams = obj.respond_to?(:get_team_objects) -media ? obj.get_team_objects.reject{ |t| t.private } : Team.where(id: team_ids, private: false)
      if teams.empty?
        TeamUser.where(user_id: @user.id, team_id: team_ids, status: 'member').exists?
      else
        teams.any?
      end
    end

  end
end
