module CheckdeskPermissions

  def self.included(base)
    base.extend(ClassMethods)
  end

  class AccessDenied < ::StandardError
    attr_reader :message

    def initialize(message)
      super
      @message = message
    end
  end

  module ClassMethods
    def find_if_can(id, current_user, context_team)
      if current_user.nil?
        self.find(id)
      else
        ability = Ability.new(current_user, context_team)
        model = self.find(id)
        if ability.can?(:read, model)
          model
        else
          raise AccessDenied, "Sorry, you can't read this #{model.class.name.downcase}"
        end
      end
    end
  end

  def permissions
    perms = Hash.new
    unless self.current_user.nil?
      ability = Ability.new(self.current_user, self.context_team)
      perms["read #{self.class}"] = ability.can?(:read, self)
      perms["update #{self.class}"] = ability.can?(:update, self)
      perms["destroy #{self.class}"] = ability.can?(:destroy, self)
      perms = perms.merge self.set_create_permissions(self.class.name)
    end
    perms.to_json
  end

  def get_create_permissions
    {
      'Team' => [Project, Account, TeamUser, User, Contact],
      'Account' => [Media],
      'Media' => [ProjectMedia, Comment, Flag, Status, Tag],
      'Project' => [ProjectSource, Source, Media, ProjectMedia],
      'Source' => [Account, ProjectSource, Project],
      'User' => [Source, TeamUser, Team, Project]
    }
  end

  def set_create_permissions(obj)
    create = self.get_create_permissions
    perms = Hash.new
    unless create[obj].nil?
      ability = Ability.new(self.current_user, self.context_team)
      create[obj].each do |data|
        model = data.new
        model.current_user = self.current_user
        model.context_team = self.context_team
        
        if model.respond_to?(:team_id) and self.context_team.present?
          model.team_id = self.context_team.id
        end

        model = self.set_project_for_permissions(model) if self.respond_to?(:project)

        perms["create #{data}"] = ability.can?(:create, model)
      end
    end
    perms
  end

  def set_project_for_permissions(model)
    if self.class.name == 'Media' and model.respond_to?(:media_id)
      model.media_id = self.id
    end
    unless self.project.nil?
      model.project_id = self.project.id if model.respond_to?(:project_id)
      model.context = self.project if model.respond_to?(:context)
    end
    model
  end

  private

  def check_ability
    unless self.current_user.nil?
      ability = Ability.new(self.current_user,  self.context_team)
      op = self.new_record? ? :create : :update
      raise "No permission to #{op} #{self.class}" unless ability.can?(op, self)
    end
  end

  def check_destroy_ability
    unless self.current_user.nil?
      ability = Ability.new(self.current_user, self.context_team)
      raise "No permission to delete #{self.class}" unless ability.can?(:destroy, self)
    end
  end
end
