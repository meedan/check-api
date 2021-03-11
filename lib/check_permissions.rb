module CheckPermissions

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
    def find_if_can(id, ability = nil)
      id = id.id if id.is_a?(ActiveRecord::Base)
      model = self.get_object(id)
      raise ActiveRecord::RecordNotFound if model.nil?
      ability ||= Ability.new
      if ability.can?(:read, model)
        model
      else
        raise AccessDenied, "Sorry, you can't read this #{model.class.name.downcase}"
      end
    end

    def get_object(id)
      if self.name == 'Project'
        self.joins(:team).where('teams.inactive' => false).where(id: id)[0]
      elsif self.name == 'Team'
        self.where(id: id, inactive: false).last
      elsif self.name == 'ProjectMedia'
        pm = self.find(id)
        pm.team&.inactive ? nil : pm
      elsif self.name == 'Version'
        tid = Team.current&.id.to_i
        self.from_partition(tid).where(id: id).last
      else
        self.find(id)
      end
    end

  end

  def permissions(ability = nil, klass = self.class)
    perms = Hash.new
    unless User.current.nil?
      ability ||= Ability.new
      perms["read #{klass}"] = ability.can?(:read, self)
      perms["update #{klass}"] = ability.can?(:update, self)
      perms["destroy #{klass}"] = ability.can?(:destroy, self)
      perms = perms.merge self.set_create_permissions(klass.name, ability)
      perms = perms.merge self.set_custom_permissions(ability)
    end
    perms.to_json
  end

  def set_custom_permissions(ability = nil)
    self.respond_to?(:custom_permissions) ? self.custom_permissions(ability) : {}
  end

  def get_create_permissions
    {
      'Team' => [Project, Account, TeamUser, User, TagText, ProjectMedia],
      'Account' => [Media, Link, Claim],
      'Media' => [ProjectMedia, Comment, Tag, Dynamic, Task],
      'Link' => [ProjectMedia, Comment, Tag, Dynamic, Task],
      'Claim' => [ProjectMedia, Comment, Tag, Dynamic, Task],
      'Project' => [Source, Media, ProjectMedia, Claim, Link],
      'ProjectMedia' => [Comment, Tag, Dynamic, Task, Relationship],
      'Source' => [Account, Project, Dynamic, Task],
      'User' => [Source, TeamUser, Team, Project]
    }
  end

  def set_create_permissions(obj, ability = nil)
    create = self.get_create_permissions
    perms = Hash.new
    unless create[obj].nil?
      ability ||= Ability.new
      create[obj].each do |data|
        model = data.new

        if model.respond_to?('team_id=') and Team.current.present?
          model.team_id = Team.current.id
        end

        if self.class.name == 'Source'
          model.source = self if model.respond_to?('source=')
        end

        model = self.set_media_for_permissions(model) if ['ProjectMedia', 'Source'].include?(self.class.name)

        perms["create #{data}"] = ability.can?(:create, model)
      end
    end
    perms
  end

  def set_media_for_permissions(model)
    model.media_id = self.id if model.respond_to?(:media_id)
    model.annotated = self if model.respond_to?(:annotated)
    model
  end

  def get_operation
    return :create if self.new_record?
    changes = self.changes.to_json
    op = :update
    if changes == '{"archived":[1,0]}'
      op = :restore
    elsif changes == '{"archived":[2,0]}'
      op = :confirm
    end
    op
  end

  def ability
    RequestStore.store[:ability] == :admin ? AdminAbility.new : Ability.new
  end

  private

  def check_ability
    unless self.skip_check_ability or User.current.nil?
      op = self.get_operation
      raise "No permission to #{op} #{self.class.name}" unless self.ability.can?(op, self)
    end
  end

  def check_destroy_ability
    unless self.skip_check_ability or RequestStore.store[:skip_check_ability] or User.current.nil?
      raise "No permission to delete #{self.class.name}" unless self.ability.can?(:destroy, self)
    end
  end
end
