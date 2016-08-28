class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :update, :destroy, :to => :cud
    @user = user ||= User.new
    # Define User abilities
    if user.has_role? :admin
      global_admin_perms
    elsif user.has_role? :owner
      owner_perms
    elsif user.has_role? :editor
      editor_perms
    elsif user.has_role? :journalist
      journalist_perms
    elsif user.has_role? :contributor
      contributor_perms
    else
      anonymous_perms
    end

  end

  private

  def global_admin_perms
    can :manage, :all
  end

  def owner_perms
    can :manage, Team, :team_users => { :user_id => @user.id }
    can :manage, Project, :team_id => @user.current_team.id
    can :manage, Media, :media_team => @user.current_team.id
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['owner', 'editor', 'journalist', 'contributor'] }
  end

  def editor_perms
    can [:create, :update], Team, :team_users => { :user_id => @user.id }
    can :manage, Project, :team_id => @user.current_team.id
    can :manage, Media, :media_team => @user.current_team.id
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['editor', 'journalist', 'contributor'] }
    #can :manage, [Media, Source, Account, Flag, Comment, Status, Tag]
  end

  def journalist_perms
    can :create, [Team, Project, Media]
    can [:update, :destroy], Project, :team_id => @user.current_team.id, :user_id => @user.id
    can [:update, :destroy], Media, :media_team => @user.current_team.id, :user_id => @user.id
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['journalist', 'contributor'] }
    #can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

  def contributor_perms
    can :create, [Team, Media]
    can [:update, :destroy], Media, :media_team => @user.current_team.id, :user_id => @user.id
    can :update, User, :id => @user.id
    #can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

  def anonymous_perms
    can :create, Team
  end

end
