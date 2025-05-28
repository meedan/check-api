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
      id = id.id if id.is_a?(ApplicationRecord)
      model = self.get_object(id)
      raise ActiveRecord::RecordNotFound if model.nil?
      ability ||= Ability.new
      if ability.can?(:read, model)
        model
      else
        raise AccessDenied, 'Not Found'
      end
    end

    def get_object(id)
      obj = nil
      if self.name == 'Version'
        tid = Team.current&.id.to_i
        obj = self.from_partition(tid).where(id: id).last
      else
        obj = self.find_by_id(id)
      end
      return nil if obj.nil?
      if self.name == 'ProjectMedia'
        obj.team&.inactive ? nil : obj
      elsif self.name == 'Team'
        obj.inactive? ? nil : obj
      else
        obj
      end
    end

  end

  def permissions(ability = nil, klass = self.class)
    perms = Hash.new
    unless User.current.nil?
      # read team permissions from cache if exists
      cache_key = ''
      if self.class.name == 'Team'
        role = User.current.role(self)
        role ||= 'authenticated'
        role = 'super_admin' if User.current.is_admin?
        cache_key = "team_permissions_#{self.private.to_i}_#{role}_role_20250526174300"
        perms = Rails.cache.read(cache_key) if Rails.cache.exist?(cache_key)
      end
      if perms.blank?
        ability ||= Ability.new
        perms["read #{klass}"] = ability.can?(:read, self)
        perms["update #{klass}"] = ability.can?(:update, self)
        perms["destroy #{klass}"] = ability.can?(:destroy, self)
        perms = perms.merge self.set_create_permissions(klass.name, ability)
        perms = perms.merge self.set_custom_permissions(ability)
        # cache team permissions
        Rails.cache.write(cache_key, perms) if self.class.name == 'Team'
      end
    end
    perms.to_json
  end

  def set_custom_permissions(ability = nil)
    self.respond_to?(:custom_permissions) ? self.custom_permissions(ability) : {}
  end

  def get_create_permissions
    {
      'Team' => [Account, TeamUser, User, TagText, ProjectMedia, TiplineNewsletter, Feed, FeedTeam, FeedInvitation, SavedSearch],
      'Account' => [Media, Link, Claim],
      'Media' => [ProjectMedia, Tag, Dynamic, Task],
      'Link' => [ProjectMedia, Tag, Dynamic, Task],
      'Claim' => [ProjectMedia, Tag, Dynamic, Task],
      'ProjectMedia' => [Tag, Dynamic, Task, Relationship, ClaimDescription],
      'Source' => [Account, Dynamic, Task],
      'User' => [Source, TeamUser, Team]
    }
  end

  def set_create_permissions(obj, ability = nil)
    create = self.get_create_permissions
    perms = Hash.new
    unless create[obj].nil?
      ability ||= Ability.new
      create[obj].each do |data|
        model = data.new

        if model.respond_to?('team_id=') && Team.current.present?
          model.team_id = Team.current.id
        end

        if self.class.name == 'Source'
          model.source = self if model.respond_to?('source=')
        end

        model = self.set_media_for_permissions(model) if ['ProjectMedia', 'Source'].include?(self.class.name)

        model.feed = Feed.new(team: Team.current) if model.class.name == 'FeedInvitation'

        perms["create #{data}"] = ability.can?(:create, model)
      end
    end
    perms
  end

  def set_media_for_permissions(model)
    model.media_id = self.id if model.respond_to?(:media_id)
    model.annotated = self if model.respond_to?(:annotated)
    model.project_media = self if model.is_a?(ClaimDescription)
    model
  end

  def get_operation
    return :create if self.new_record?
    changes = self.changes.to_json
    op = :update
    if changes.include?('"archived":[1,0]')
      op = :restore
    elsif changes.include?('"archived":[2,0]')
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
