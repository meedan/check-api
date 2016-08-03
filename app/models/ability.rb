class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user ||= User.new

    # team = xx should load the current team
    team = @user.teams.last
    # Define User abilities
    if user.has_role? :admin, team
      global_admin_perms
    elsif user.has_role? :owner, team
      owner_perms
    elsif user.has_role? :editor, team
      editor_perms
    elsif user.has_role? :journalist, team
      journalist_perms
    elsif user.has_role? :contributor, team
      contributor_perms
    end

  end

  private

  def global_admin_perms
    can :manage, :all
  end

  def owner_perms
    can :manage, :all

  end

  def editor_perms
    can :update, Team
    can :create, Project
    can [:update, :destroy], Project, :user_id => @user.id
    can :manage, [Media, Source, Account, Flag, Comment, Status, Tag]
    can :update, [Media, Source, Account], :user_id => @user.id
  end

  def journalist_perms
    can :create, Project
    can :update, Project
    can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

  def contributor_perms
    can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

end
