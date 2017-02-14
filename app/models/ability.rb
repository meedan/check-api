class Ability
  include CanCan::Ability

  def initialize(user = nil)
    alias_action :create, :update, :destroy, :to => :cud
    @user = User.current ||= user || User.new
    @context_team = Team.current ||= @user.current_team
    # Define User abilities
    if @user.is_admin?
      global_admin_perms
    else
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
    end
  end

  private

  def global_admin_perms
    can :access, :rails_admin
    can :dashboard
    can :manage, :all
  end

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can [:update, :destroy], User, :team_users => { :team_id => @context_team.id, role: ['owner', 'editor', 'journalist', 'contributor'] }
    can :destroy, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['owner']
    can :update, TeamUser, team_id: @context_team.id
    cannot :update, TeamUser, team_id: @context_team.id, user_id: @user.id
    can :destroy, Contact, :team_id => @context_team.id
    can :destroy, Project, :team_id => @context_team.id
    can :destroy, [Media, Link, Claim] do |obj|
      obj.get_team.include? @context_team.id
    end
    can :destroy, [ProjectMedia, ProjectSource] do |obj|
      obj.get_team.include? @context_team.id
    end
    %w(annotation comment flag status tag embed).each do |annotation_type|
      can :destroy, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include? @context_team.id
      end
    end
    can :destroy, PaperTrail::Version do |obj|
      a = nil
      v_obj = obj.item_type.constantize.where(id: obj.item_id).last
      a = v_obj if v_obj.is_annotation?
      !a.nil? and a.get_team.include? @context_team.id
    end
  end

  def editor_perms
    can :update, User, :team_users => { :team_id => @context_team.id, role: ['editor'] }
    can :update, Team, :id => @context_team.id
    can :create, TeamUser, :team_id => @context_team.id, role: ['editor']
    can :update, TeamUser, team_id: @context_team.id, role: ['editor', 'journalist', 'contributor']
    cannot :update, TeamUser, team_id: @context_team.id, user_id: @user.id
    can [:create, :update], Contact, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id
    can [:create, :update], [ProjectMedia, ProjectSource], project: { team: { team_users: { team_id: @context_team.id }}}
    %w(annotation comment flag).each do |annotation_type|
      can :update, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include? @context_team.id
      end
    end
  end

  def journalist_perms
    can :update, User, :team_users => { :team_id => @context_team.id, role: ['journalist', 'contributor'] }
    can :create, TeamUser, :team_id => @context_team.id, role: ['journalist', 'contributor']
    can :create, Project, :team_id => @context_team.id
    can :update, Project, :team_id => @context_team.id, :user_id => @user.id
    can :update, [Media, Link, Claim], projects: { team: { team_users: { team_id: @context_team.id }}}

    can :create, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include? @context_team.id and (flag.flag.to_s == 'Mark as graphic')
    end
    can :update, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include? @context_team.id and (flag.annotator_id.to_i == @user.id)
    end
    %w(status tag).each do |annotation_type|
      can :create, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        obj.get_team.include? @context_team.id
      end
    end
    can :update, Status, ['annotation_type = ?', 'status'] do |obj|
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
    can [:create, :update], ProjectSource, project: { team: { team_users: { team_id: @context_team.id }}}, source: { user_id: @user.id }
    can :create, ProjectMedia, project: { team: { team_users: { team_id: @context_team.id }}}
    can [:update, :destroy], ProjectMedia, project: { team: { team_users: { team_id: @context_team.id }}}, media: { user_id: @user.id }
    can :update, Comment, ['annotation_type = ?', 'comment'] do |obj|
      obj.get_team.include? @context_team.id and (obj.annotator_id.to_i == @user.id)
    end
    can :create, Flag, ['annotation_type = ?', 'flag'] do |flag|
      flag.get_team.include? @context_team.id and (['Spam', 'Graphic content'].include?flag.flag.to_s)
    end
    can :create, Tag, ['annotation_type = ?', 'tag'] do |obj|
      (obj.get_team.include? @context_team.id and obj.annotated_type === 'ProjectMedia' and obj.annotated.user_id.to_i === @user.id) or obj.annotated_type === 'Source'
    end
    can :destroy, TeamUser, user_id: @user.id
    can :destroy, Tag, ['annotation_type = ?', 'tag'] do |obj|
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
    can :create, User
    can :create, PaperTrail::Version
    can :read, Team, :private => false
    can :read, Team, :private => true, :team_users => { :user_id => @user.id, :status => 'member' }

    # A @user can read a user if:
    # 1) @user is the same as target user
    # 2) target user is a member of at least one public team
    # 3) @user is a member of at least one same team as the target user
    can :read, User, id: @user.id
    can :read, User, teams: { private: false }
    can :read, User, team_users: { status: 'member', team: { team_users: { user_id: @user.id, status: 'member' }}}

    # A @user can read contact, project or team user if:
    # 1) team is private and @user is a member of that team
    # 2) team user is not private
    can :read, [Contact, Project, TeamUser], team: { team_users: { user_id: @user.id, status: 'member'} }
    can :read, [Contact, Project, TeamUser], team: { private: false }

    # A @user can read any of those objects if:
    # 1) it's a source related to him/her or not related to any user
    # 2) it's related to at least one public team
    # 3) it's related to a private team which the @user has access to

    can :read, [Account, ProjectMedia, Source], user_id: [@user.id, nil]
    can :read, [Source, Media, Link, Claim], projects: { team: { private: false }}
    can :read, [Source, Media, Link, Claim], projects: { team: { team_users: { user_id: @user.id, status: 'member' }}}

    can :read, [Account, ProjectSource], source: { user_id: [@user.id, nil] }
    can :read, Account, source: { projects: { team: { private: false, team_users: { user_id: @user.id }}}}
    can :read, Account, source: { projects: { team: { team_users: { user_id: @user.id, status: 'member' }}}}
    can :read, [ProjectMedia, ProjectSource], project: { team: { private: false, team_users: { user_id: @user.id }}}
    can :read, [ProjectMedia, ProjectSource], project: { team: { team_users: { user_id: @user.id, status: 'member' }}}

    %w(comment flag status embed tag).each do |annotation_type|
      can :read, annotation_type.classify.constantize, ['annotation_type = ?', annotation_type] do |obj|
        if obj.annotation_type == annotation_type
          team_ids = obj.get_team
          teams = Team.where(id: team_ids, private: false)
          if teams.empty?
            tu = TeamUser.where(user_id: @user.id, team_id: team_ids, status: 'member')
            TeamUser.where(user_id: @user.id, team_id: team_ids, status: 'member').exists?
          else
            teams.any?
          end
        end
      end
    end

    cannot :manage, ApiKey
  end
end
