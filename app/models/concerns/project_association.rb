require 'active_support/concern'

module ProjectAssociation
  extend ActiveSupport::Concern


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
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    before_validation :set_media_or_source, :set_user, on: :create

    private

    def set_media_or_source
      self.set_media if self.class_name == 'ProjectMedia'
      self.set_source if self.class_name == 'ProjectSource'
    end

    def set_user
      self.user = User.current unless User.current.nil?
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
        s = self.create_source
        self.source_id = s.id unless s.nil?
      end
    end

  end

end
