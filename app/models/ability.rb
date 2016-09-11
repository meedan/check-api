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
    can [:update, :destroy], User, :team_users => { :team_id => @context_team.id, role: ['owner'] }
    can :destroy, Team, :id => @context_team.id
    can [:create, :update], TeamUser, :team_id => @context_team.id, role: ['owner']
    can :destroy, Contact, :team_id => @context_team.id
  end

  def editor_perms
    can [:update, :destroy], User, :team_users => { :team_id => @context_team.id, role: ['editor'] }
    can :update, Team, :id => @context_team.id
    can [:create, :update], TeamUser, :team_id => @context_team.id, role: ['editor']
    can [:create, :update], Contact, :team_id => @context_team.id
    can [:update, :destroy], Project, :team_id => @context_team.id
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @context_team.id
    end
    can :cud, [ProjectMedia, ProjectSource] do |obj|
      obj.get_team.include? @context_team.id
    end
    can [:update, :destroy], [Comment, Tag] do |obj|
      obj.get_team.include? @context_team.id
    end
    can [:update, :destroy], Flag do |flag|
      flag.get_team.include? @context_team.id
    end
    can [:create, :destroy], Status do |status|
      status.get_team.include? @context_team.id
    end
  end

  def journalist_perms
    can [:update, :destroy], User, :team_users => { :team_id => @context_team.id, role: ['journalist', 'contributor'] }
    can [:create, :update], TeamUser, :team_id => @context_team.id, role: ['journalist', 'contributor']
    can :create, Project
    can [:update, :destroy], Project, :team_id => @context_team.id, :user_id => @user.id
    can :create, Flag do |flag|
      flag.get_team.include? @context_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can [:update, :destroy], Flag do |flag|
      flag.get_team.include? @context_team.id and (flag.annotator_id.to_i == @user.id)
    end
    can [:create, :destroy], Status do |status|
      status.get_team.include? @context_team.id and (status.annotator_id.to_i == @user.id)
    end
  end

  def contributor_perms
    can :update, User, :id => @user.id
    can :create, [Media, Account, Source, Comment, Tag]
    can :update, Media, :user_id => @user.id
    can [:update, :destroy], Media do |obj|
      obj.get_team.include? @context_team.id and (obj.user_id == @user.id)
    end
    can :update, [Account, Source]
    can :cud, ProjectSource do |obj|
      obj.get_team.include? @context_team.id and (obj.source.user_id == @user.id)
    end
    can :cud, ProjectMedia do |obj|
      obj.get_team.include? @context_team.id and (obj.media.user_id == @user.id)
    end
    can [:update, :destroy], [Comment, Tag] do |obj|
      obj.get_team.include? @context_team.id and (obj.annotator_id.to_i == @user.id)
    end
    can :create, Flag do |flag|
      flag.get_team.include? @context_team.id and (['Spam', 'Graphic content'].include?flag.flag.to_s)
    end
  end

  def authenticated_perms
    #can :read, User, :id => @user.id
    can :create, Team
    can :create, TeamUser, :user_id => @user.id, status: ['member', 'requested']
  end

  # extra permissions for all users
  def extra_perms_for_all_users
    can [:create, :read], User
    can :read, Team, :private => false
    can :read, Team, :private => true, :team_users => { :user_id => @user.id, :status => 'member' }
    #can :read, User do |user|
    #  t = user.teams.where(id: @context_team.id).last
    #  unless t.nil?
    #    if t.private
    #      tu = t.team_users.where(user_id: @user.id, status: 'member')
    #      !tu.last.nil?
    #    else
    #      !t.private
    #    end
    #  end
    #end

    can :read, [Contact, Project, TeamUser] do |obj|
      if obj.team.private
        tu = TeamUser.where(user_id: @user.id, team_id: obj.team.id, status: 'member')
        !tu.last.nil?
      else
        !obj.team.private
      end
    end
    
    can :read, [Account, Source, Media, ProjectMedia, ProjectSource, Comment, Flag, Status, Tag] do |obj|
      if obj.respond_to?(:user_id)
        obj.user_id === @user.id || obj.user_id.nil?
      else
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
end
