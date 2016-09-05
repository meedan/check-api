class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :update, :destroy, :to => :cud
    @user = user ||= User.new
    # Define User abilities
    extra_perms_for_all_users
    if user.role? :admin
      global_admin_perms
    end
    if user.role? :owner
      owner_perms
    end
    if user.role? :editor
      editor_perms
    end
    if user.role? :journalist
      journalist_perms
    end
    if user.role? :contributor
      contributor_perms
    end
    if user.id
      authenticated_perms
    end
  end

  private

  def global_admin_perms
    can :manage, :all
  end

  def owner_perms
    can :destroy, Team, :id => @user.current_team.id
    can [:create, :update], TeamUser, :team_id => @user.current_team.id, role: ['owner']
    can :destroy, Contact, :team_id => @user.current_team.id
    can :update, Media, :user_id => @user.id
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['owner', 'editor', 'journalist', 'contributor'] }
  end

  def editor_perms
    can :update, Team, :id => @user.current_team.id
    can [:create, :update], TeamUser, :team_id => @user.current_team.id, role: ['editor']
    can [:create, :update], Contact, :team_id => @user.current_team.id
    can [:update, :destroy], Project, :team_id => @user.current_team.id
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @user.current_team.id
    end
    can :cud, [ProjectMedia, ProjectSource] do |obj|
      obj.get_team.include? @user.current_team.id
    end
    can :manage, Comment do |comment|
      comment.get_team.include? @user.current_team.id
    end
    can [:update, :destroy], Flag do |flag|
      flag.get_team.include? @user.current_team.id
    end
    can [:create, :destroy], Status do |status|
      status.get_team.include? @user.current_team.id
    end
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['editor', 'journalist', 'contributor'] }
  end

  def journalist_perms
    can [:create, :update], TeamUser, :team_id => @user.current_team.id, role: ['journalist', 'contributor']
    can :create, Project
    can [:update, :destroy], Project, :team_id => @user.current_team.id, :user_id => @user.id
    can :manage, Comment do |comment|
      comment.get_team.include? @user.current_team.id and (comment.media.user_id == @user.id)
    end
    can :create, Flag do |flag|
      flag.get_team.include? @user.current_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can [:update, :destroy], Flag do |flag|
      flag.get_team.include? @user.current_team.id and (flag.annotator_id == @user.id)
    end
    can [:create, :destroy], Status do |status|
      status.get_team.include? @user.current_team.id and (status.annotator_id == @user.id)
    end
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['journalist', 'contributor'] }
  end

  def contributor_perms
    can :create, [Media, Account, Source, Comment, Tag]
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @user.current_team.id and (obj.user_id == @user.id)
    end
    can :update, [Account, Source]
    can :cud, [ProjectMedia, ProjectSource] do |obj|
      obj.get_team.include? @user.current_team.id and (obj.media.user_id == @user.id)
    end
    can :create, Flag do |flag|
      flag.get_team.include? @user.current_team.id and (['Spam', 'Graphic content'].include?flag.flag.to_s)
    end
    can :update, User, :id => @user.id
  end

  def authenticated_perms
    can :create, Team
    can :create, TeamUser, :user_id => @user.id, status: ['member', 'requested']
  end

  # extra permissions for all users
  def extra_perms_for_all_users
    can :create, User
    can :read, Team, :private => false
    can :read, Team, :private => true, :team_users => { :user_id => @user.id, :status => 'member' }
    can :read, Project do |project|
      if project.team.private
        tu = TeamUser.where(user_id: @user.id, team_id: project.team.id, status: 'member')
        !tu.last.nil?
      else
        !project.team.private
      end
    end
    can :read, [Account, Source]
    can :read, [Media, Comment, Flag, Status] do |obj|
      teams = Team.where(id: obj.get_team, private: false).map(&:id)
      if teams.empty?
        tu = TeamUser.where(user_id: @user.id, team_id: obj.get_team, status: 'member').map(&:id)
        tu.any?
      else
        teams.any?
      end
    end
  end

end
