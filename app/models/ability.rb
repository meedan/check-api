class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :update, :destroy, :to => :cud
    @user = user ||= User.new
    # Define User abilities
    if user.has_role? :admin
      perms = global_admin_perms
    elsif user.has_role? :owner
      perms = owner_perms
    elsif user.has_role? :editor
      perms = editor_perms
    elsif user.has_role? :journalist
      perms = journalist_perms
    elsif user.has_role? :contributor
      perms = contributor_perms
    elsif user.id
      perms = authenticated_perms
    else
      perms = anonymous_perms
    end
    return perms, extra_perms
  end

  private

  def global_admin_perms
    can :manage, :all
  end

  def owner_perms
    can :manage, Tag
    can :cud, Team, :id => @user.current_team.id
    can :cud, Project, :team_id => @user.current_team.id
    can :create, [Media, Account, Source]
    can :update, [Account, Source]
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @user.current_team.id
    end
    can :cud, ProjectMedia do |pm|
      pm.get_team.include? @user.current_team.id
    end
    can :cud, ProjectSource do |ps|
      ps.get_team.include? @user.current_team.id
    end
    can :manage, Comment do |comment|
      comment.get_team.include? @user.current_team.id
    end
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['owner', 'editor', 'journalist', 'contributor'] }
    can [:update, :destroy], TeamUser, :team_id => @user.current_team.id, role: ['owner', 'editor', 'journalist', 'contributor']
    can :create, Flag do |flag|
      flag.get_team.include? @user.current_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can [:create, :destroy], Status do |status|
      status.get_team.include? @user.current_team.id
    end
  end

  def editor_perms
    can :manage, Tag
    can [:create, :update], Team, :id => @user.current_team.id
    can :cud, Project, :team_id => @user.current_team.id
    can :create, [Media, Account, Source]
    can :update, [Account, Source]
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @user.current_team.id
    end
    can :cud, ProjectMedia do |pm|
      pm.get_team.include? @user.current_team.id
    end
    can :cud, ProjectSource do |ps|
      ps.get_team.include? @user.current_team.id
    end
    can :manage, Comment do |comment|
      comment.get_team.include? @user.current_team.id
    end
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['editor', 'journalist', 'contributor'] }
    can [:update, :destroy], TeamUser, :team_id => @user.current_team.id, role: ['editor', 'journalist', 'contributor']
    can :create, Flag do |flag|
      flag.get_team.include? @user.current_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can [:create, :destroy], Status do |status|
      status.get_team.include? @user.current_team.id
    end
  end

  def journalist_perms
    can :create, [Team, Project, Media, Account, Source, Comment, Tag]
    can [:update, :destroy], Project, :team_id => @user.current_team.id, :user_id => @user.id
    can :update, [Account, Source]
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @user.current_team.id and (obj.user_id == @user.id)
    end
    can :cud, ProjectMedia do |pm|
      pm.get_team.include? @user.current_team.id and (pm.media.user_id == @user.id)
    end
    can :cud, ProjectSource do |ps|
      ps.get_team.include? @user.current_team.id and (pm.source.user_id == @user.id)
    end
    can [:update, :destroy], User, :team_users => { :team_id => @user.current_team.id, role: ['journalist', 'contributor'] }
    can [:update, :destroy], TeamUser, :team_id => @user.current_team.id, role: ['journalist', 'contributor']
    can [:update, :destroy], Flag do |flag|
      flag.get_team.include? @user.current_team.id and (flag.annotator_id == @user.id)
    end
    can :create, Flag do |flag|
      flag.get_team.include? @user.current_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can [:create, :destroy], Status do |status|
      status.get_team.include? @user.current_team.id and (status.annotator_id == @user.id)
    end
  end

  def contributor_perms
    can :create, [Team, Media, Account, Source, Comment, Tag]
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @user.current_team.id and (obj.user_id == @user.id)
    end
    can :update, [Account, Source]
    can :cud, ProjectMedia do |pm|
      pm.get_team.include? @user.current_team.id and (pm.media.user_id == @user.id)
    end
    can :cud, ProjectSource do |ps|
      ps.get_team.include? @user.current_team.id and (pm.source.user_id == @user.id)
    end
    can :update, User, :id => @user.id
    can :create, Flag do |flag|
      flag.get_team.include? @user.current_team.id and (['Spam', 'Graphic content'].include?flag.flag.to_s)
    end
  end

  def authenticated_perms
    can :create, Team
  end

  def anonymous_perms

  end

  # extra permissions for all users
  def extra_perms
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
