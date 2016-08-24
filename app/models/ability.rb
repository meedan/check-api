class Ability
  include CanCan::Ability

  def initialize(user)
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
    can :manage, [Team, Project, Media]
    can :destroy, User, :team_users => { :role => ['owner', 'editor', 'journalist']}
  end

  def editor_perms
    can :manage, [Project, Media]
    can [:create, :update], Team
    #can :manage, [Media, Source, Account, Flag, Comment, Status, Tag]
  end

  def journalist_perms
    can :create, [Team, Project, Media]
    can [:update, :destroy], [Project, Media], :user_id => @user.id
    #can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

  def contributor_perms
    can :create, [Team, Media]
    can [:update, :destroy], Media, :user_id => @user.id
    #can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

  def anonymous_perms
    can :create, Team
  end

end
