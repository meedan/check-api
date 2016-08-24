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
    end

  end

  private

  def global_admin_perms
    can :manage, :all
  end

  def owner_perms
    can :manage, Project

  end

  def editor_perms
    can :manage, Project
    can :update, Team
    can :manage, [Media, Source, Account, Flag, Comment, Status, Tag]
  end

  def journalist_perms
    can :create, Project
    can [:update, :destroy], Project, :user_id => @user.id
    can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

  def contributor_perms
    can [:create, :update], [Media, Source, Account, Flag, Comment, Status, Tag], :user_id => @user.id
  end

end
