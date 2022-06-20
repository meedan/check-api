require 'active_support/concern'
require 'error_codes'

module ProjectAssociation
  extend ActiveSupport::Concern

  def check_search_project
    self.project.check_search_project unless self.project.nil?
  end

  def project_was
    Project.find_by_id(self.previous_project_id) unless self.previous_project_id.nil?
  end

  def check_search_project_was
    self.project_was.check_search_project unless self.project_was.nil?
  end

  def check_search_team
    self.team.check_search_team
  end

  def check_search_trash
    self.team.check_search_trash
  end

  def check_search_unconfirmed
    self.team.check_search_unconfirmed
  end

  def check_search_spam
    self.team.check_search_spam
  end

  def as_json(_options = {})
    super.merge({ full_url: self.full_url.to_s })
  end

  module ClassMethods
    def belonged_to_project(objid, pid, tid)
      obj = self.find_by_id objid
      if obj && (obj.project_id == pid || (self.to_s == 'ProjectMedia' && !ProjectMedia.where(id: objid, team_id: tid).last.nil?))
        return obj.id
      else
        obj = ProjectMedia.where(project_id: pid, media_id: objid).last
        return obj.id if obj
      end
    end
  end

  included do
    attr_accessor :url, :disable_es_callbacks

    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include CheckElasticSearch

    before_validation :set_media_and_source, :set_user, on: :create

    validate :is_unique, on: :create, unless: proc { |p| p.is_being_copied }

    after_commit :add_elasticsearch_data, on: :create
    after_commit :update_elasticsearch_data, on: :update
    after_commit :destroy_elasticsearch_media , on: :destroy

    def get_versions_log(event_types = nil, field_names = nil, annotation_types = nil, whodunnit = nil, include_related = false)
      whodunnit = User.where(login: whodunnit).last unless whodunnit.blank?
      log = Version.from_partition(self.team_id).where(associated_type: self.class.name, associated_id: self.get_associated_ids_for_versions_log(include_related))
      log = log.where(event_type: event_types) unless event_types.blank?
      log = log.where(whodunnit: whodunnit.id) unless whodunnit.nil?
      log = log.where('version_field_name(event_type, object_after) IN (?)', [field_names].flatten) unless field_names.blank?
      log = log.where('version_annotation_type(event_type, object_after) IN (?)', [annotation_types].flatten) unless annotation_types.blank?
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
      obj = self.class.find_by_id(self.id)
      return if obj.nil?
      data = {
        'team_id' => obj.team_id,
        'archived' => { method: 'archived', klass: obj.class.name, id: obj.id, type: 'int' },
        'sources_count' => { method: 'sources_count', klass: 'ProjectMedia', id: obj.id, type: 'int' },
        'user_id' => obj.user_id,
        'read' => obj.read.to_i,
        'media_published_at' => obj.media_published_at,
        'source_id' => obj.source_id,
        'project_id' => obj.project_id,
        'channel' => obj.channel.values.flatten.map(&:to_i),
        'updated_at' => obj.updated_at.utc
      }
      options = { keys: data.keys, data: data, obj: obj }
      ElasticSearchWorker.perform_in(1.second, YAML::dump(obj), YAML::dump(options), 'update_doc')
    end

    def destroy_elasticsearch_media
      destroy_es_items(MediaSearch, 'destroy_doc')
    end

    def is_being_copied
      self.team && self.team.is_being_copied
    end

    private

    def set_media_and_source
      self.set_media
      set_source if self.source_id.blank? && !self.media.nil?
    end

    def set_source
      a = self.media.account
      s = a.sources.first unless a.nil?
      team = self.team || Team.current
      unless team.nil? || s.nil? || s.team_id == team.id
        # clone exiting source to current team
        # This case happens when add exiting media
        s = Source.create_source(s.name, team)
        as = AccountSource.where(account_id: a.id, source_id: s.id).last
        a.create_account_source(s) if as.nil?
      end
      self.source_id = s.id unless s.blank?
    end

    def set_user
      self.user = User.current unless User.current.nil?
    end

    def is_unique
      obj_name = 'media'
      obj = ProjectMedia.where(team_id: self.team_id, media_id: self.media_id).last
      unless obj.nil?
        error = {
          message: I18n.t("#{obj_name}_exists", team_id: obj.team_id, id: obj.id),
          code: LapisConstants::ErrorCodes::const_get('DUPLICATED'),
          data: {
            team_id: obj.team_id,
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
      unless self.url.blank? && self.quote.blank? && self.file.blank? && self.media_type != 'Blank'
        m = self.create_media
        self.media_id = m.id unless m.nil?
      end
    end
  end
end
