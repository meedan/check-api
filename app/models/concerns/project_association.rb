require 'active_support/concern'
require 'error_codes'

module ProjectAssociation
  extend ActiveSupport::Concern

  def check_search_team
    team = self.respond_to?(:team) ? self.team : self.project.team
    team.check_search_team
  end

  def check_search_trash
    team = self.respond_to?(:team) ? self.team : self.project.team
    team.check_search_trash
  end

  def check_search_project(project = nil)
    project ||= self.project
    return nil if project.nil?
    project.check_search_project
  end

  def check_search_project_was
    self.check_search_project(self.project_was)
  end

  def as_json(_options = {})
    super.merge({ full_url: self.full_url.to_s })
  end

  module ClassMethods
    def belonged_to_project(objid, pid, tid)
      obj = self.find_by_id objid
      if obj && (obj.project_id == pid || obj.versions.from_partition(obj.team_id).where_object(project_id: pid).exists? || (self.to_s == 'ProjectMedia' && !ProjectMedia.where(id: objid, team_id: tid).last.nil?))
        return obj.id
      else
        key = self.to_s == 'ProjectMedia' ? :media_id : :source_id
        obj = self.where(project_id: pid).where("#{key} = ?", objid).last
        return obj.id if obj
      end
    end
  end

  included do
    attr_accessor :url, :disable_es_callbacks

    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include CheckElasticSearch

    before_validation :set_media_or_source, :set_user, on: :create

    validate :is_unique, on: :create, unless: proc { |p| p.is_being_copied }

    after_commit :add_elasticsearch_data, on: :create
    after_commit :update_elasticsearch_data, on: :update
    after_commit :destroy_elasticsearch_media , on: :destroy

    def get_versions_log(event_types = nil, field_names = nil, annotation_types = nil, whodunnit = nil, include_related = false)
      whodunnit = User.where(login: whodunnit).last unless whodunnit.blank?
      log = Version.from_partition(self.team_id).where(associated_type: self.class.name, associated_id: self.get_associated_ids_for_versions_log(include_related))
      log = log.where(event_type: event_types) unless event_types.blank?
      log = log.where(whodunnit: whodunnit.id) unless whodunnit.nil?
      log = log.where('version_field_name(event_type, object_after) IN (?)', field_names.concat([''])) unless field_names.blank?
      log = log.where('version_annotation_type(event_type, object_after) IN (?)', annotation_types.concat([''])) unless annotation_types.blank?
      log.order('created_at ASC')
    end

    def get_associated_ids_for_versions_log(include_related = false)
      (self.is_a?(ProjectMedia) && include_related) ? self.related_items_ids : [self.id]
    end

    def get_versions_log_count
      self.reload.cached_annotations_count
    end

    def add_elasticsearch_data
      return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
      options = { obj: self }
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'create_doc')
    end

    def update_elasticsearch_data
      return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
      keys = %w(project_id team_id)
      data = {
        'project_id' => self.project_id,
        'team_id' => self.team_id
      }
      if self.class_name == 'ProjectMedia'
        keys.concat(%w(archived sources_count))
        data = data.merge({
          'archived' => self.archived.to_i,
          'sources_count' => self.sources_count
        })
      end
      options = { keys: keys, data: data, parent: self }
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_doc')
    end

    def destroy_elasticsearch_media
      destroy_es_items(MediaSearch, 'destroy_doc')
    end

    def is_being_copied
      self.project && self.project.is_being_copied
    end

    private

    def set_media_or_source
      self.set_media if self.class_name == 'ProjectMedia'
      self.set_source if self.class_name == 'ProjectSource'
    end

    def set_user
      self.user = User.current unless User.current.nil?
    end

    def is_unique
      if self.class_name == 'ProjectSource'
        obj_name = 'source'
        obj = ProjectSource.where(project_id: self.project_id, source_id: self.source_id).last
      else
        obj_name = 'media'
        obj = ProjectMedia.where(team_id: self.team_id, media_id: self.media_id).last
      end
      unless obj.nil?
        error = {
          message: I18n.t("#{obj_name}_exists", project_id: obj.project_id, id: obj.id),
          code: LapisConstants::ErrorCodes::const_get('DUPLICATED'),
          data: {
            project_id: obj.project_id,
            type: obj_name,
            id: obj.id,
            url: obj.full_url
          }
        }
        raise error.to_json
      end
    end

    protected

    def set_media
      unless self.url.blank? && self.quote.blank? && self.file.blank?
        m = self.create_media
        error_messages = m.errors.messages.values.flatten
        if error_messages.any?
          error_messages.each { |error| errors.add(:base, error) }
        else
          self.media_id = m.id unless m.nil?
        end
      end
    end

    def set_source
      unless self.name.blank?
        s = Source.create_source(self.name)
        self.source_id = s.id unless s.nil?
      end
    end

  end

end
