class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user ||= User.new

    # Define User abilities
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
  end

end
