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
    can :manage, Team
  end

  def editor_perms
    can :manage, [User, Project, Media, Source, Account]
  end

  def journalist_perms
    can :create, [User, Project]
    can :update, [User, Media, Source, Account]
    can :update, Project, [:title, :description]
  end

  def contributor_perms
    can :read, :all
    can :create, [Media, Source, Account]
    can :update, [Media, Source, Account], :user_id => @user.id
    cannot :create, Project
  end

end
