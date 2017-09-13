class AdminAbility
  include CheckBasicAbilities

  def initialize(user = nil)
    alias_action :create, :read, :update, :destroy, :to => :crud
    @user = User.current ||= user || User.new
    @teams = @user.teams_owned.map(&:id)
    # Define User abilities
    if @user.is_admin?
      global_admin_perms
    else
      owner_perms if @teams.any?
    end
  end

  private

  def owner_perms
    can :access, :rails_admin
    can :dashboard

    can [:read, :update], Team, :id => @teams

    can :create, PaperTrail::Version
  end

end
