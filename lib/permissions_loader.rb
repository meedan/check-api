require 'graphql/batch'

class PermissionsLoader < GraphQL::Batch::Loader
  def initialize(ability)
    @ability = ability
  end

  def perform(ids)
    objs = ProjectMedia.where(id: ids).all

    if objs.size == 1
      only = objs.first
      only.cached_permissions = only.permissions
      fulfill(only.id, only)
      return
    end

    if User.current.nil?
      first = objs.first
      first.cached_permissions = first.permissions
      objs.each do |obj|
        obj.cached_permissions ||= first.cached_permissions
        fulfill(obj.id, obj)
      end
      return
    end

    archived = []
    owned = []
    other = []
    team = objs.first.project.team
    objs.each do |obj|
      obj.team = team
      if obj.user_id == User.current.id
        owned << obj
      elsif obj.archived_was
        archived << obj
      else
        other << obj
      end
    end
    [owned.first, archived.first, other.first].each do |obj|
      obj.cached_permissions = obj.permissions unless obj.nil?
    end
    owned.each { |obj| obj.cached_permissions ||= owned.first.cached_permissions; fulfill(obj.id, obj) }
    archived.each { |obj| obj.cached_permissions ||= archived.first.cached_permissions; fulfill(obj.id, obj) }
    other.each { |obj| obj.cached_permissions ||= other.first.cached_permissions; fulfill(obj.id, obj) } 
  end
end
