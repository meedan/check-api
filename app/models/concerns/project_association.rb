require 'active_support/concern'

module ProjectAssociation
  extend ActiveSupport::Concern

  def check_search_team
    self.project.team.check_search_team
  end

  def check_search_project
    CheckSearch.new({ 'parent' => { 'type' => 'project', 'id' => self.project.id }, 'projects' => [self.project.id] }.to_json)
  end

  def as_json(_options = {})
    super.merge({ full_url: self.full_url.to_s })
  end

  module ClassMethods
    def belonged_to_project(objid, pid)
      obj = self.find_by_id objid
      if obj && (obj.project_id == pid || obj.versions.where_object(project_id: pid).exists?)
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

    validate :is_unique, on: :create

    def get_versions_log
      PaperTrail::Version.where(associated_type: self.class.name, associated_id: self.id).order('created_at ASC')
    end

    def get_versions_log_count
      self.reload.cached_annotations_count
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
        obj = ProjectMedia.where(project_id: self.project_id, media_id: self.media_id).last
      end
      unless obj.nil?
        error = {
          message: I18n.t("#{obj_name}_exists", project_id: obj.project_id, id: obj.id),
          code: 'ERR_OBJECT_EXISTS',
          data: {
            project_id: obj.project_id,
            type: obj_name,
            id: obj.id
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
