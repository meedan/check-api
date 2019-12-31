require 'graphql/batch'

class PermissionsLoader < GraphQL::Batch::Loader
  def initialize(ability)
    @ability = ability
  end

  def load_permissions_for_anonymous_user(objs)
    first = objs.first
    first.cached_permissions = first.permissions
    objs.each do |obj|
      obj.cached_permissions ||= first.cached_permissions
      fulfill(obj.id, obj)
    end
  end

  def load_permissions_for_single_item(objs)
    only = objs.first
    only.cached_permissions = only.permissions
    fulfill(only.id, only)
  end

  def clone_permissions(archived_owned, archived, owned, other)
    [archived_owned.first, owned.first, archived.first, other.first].each do |obj|
      obj.cached_permissions = obj.permissions unless obj.nil?
    end

    archived_owned.each { |obj| obj.cached_permissions ||= archived_owned.first.cached_permissions; fulfill(obj.id, obj) }
    owned.each { |obj| obj.cached_permissions ||= owned.first.cached_permissions; fulfill(obj.id, obj) }
    archived.each { |obj| obj.cached_permissions ||= archived.first.cached_permissions; fulfill(obj.id, obj) }
    other.each { |obj| obj.cached_permissions ||= other.first.cached_permissions; fulfill(obj.id, obj) }
  end

  def archived_and_owned?(obj)
    obj.user_id == User.current.id && obj.archived_was
  end

  def perform(ids)
    objs = ProjectMedia.where(id: ids).all

    if objs.size == 1
      load_permissions_for_single_item(objs)
      return
    end

    if User.current.nil?
      load_permissions_for_anonymous_user(objs)
      return
    end

    archived = []
    archived_owned = []
    owned = []
    other = []
    team = objs.first.team

    objs.each do |obj|
      obj.team = team
      if archived_and_owned?(obj)
        archived_owned << obj
      elsif obj.user_id == User.current.id
        owned << obj
      elsif obj.archived_was
        archived << obj
      else
        other << obj
      end
    end

    clone_permissions(archived_owned, archived, owned, other)
  end
end
