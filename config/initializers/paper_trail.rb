PaperTrail.config.track_associations = false
PaperTrail.serializer = PaperTrail::Serializers::JSON

module PaperTrail
  module AttributeSerializers
    class CastAttributeSerializer
      def initialize(klass)
        @klass = klass
      end
    end
  end

  module CheckdeskExtensions
    def self.included(base)
      base.class_eval do
        before_create :set_object_after
      end
    end

    def item_class
      self.item_type.constantize
    end

    def item
      self.item_class.where(id: self.item_id).last
    end

    def project_media
      self.item.project_media if self.item.respond_to?(:project_media)
    end

    def source
      self.item.source if self.item.respond_to?(:source)
    end

    def dbid
      self.id
    end

    def annotation
      Annotation.find(self.item_id) if self.item_class.new.is_annotation?
    end

    def user
      self.whodunnit.nil? ? nil : User.where(id: self.whodunnit.to_i).last
    end

    def apply_changes
      object = self.object.nil? ? {} : JSON.parse(self.object)
      changes = JSON.parse(self.object_changes)
      if self.item_class.new.is_annotation?
        object['data'] = YAML.load(object['data']) if object['data']
        changes['data'].collect!{ |change| YAML.load(change) unless change.nil? } if changes['data']
      end
      if self.item_class.new.is_a?(Team)
        object['settings'] = YAML.load(object['settings']) if object['settings']
        changes['settings'].collect!{ |change| YAML.load(change) unless change.nil? } if changes['settings']
      end
      changes.each do |key, pair|
        object[key] = pair[1]
      end
      object.to_json
    end

    def set_object_after
      self.object_after = self.apply_changes
    end
  end
end

PaperTrail::Version.send(:include, PaperTrail::CheckdeskExtensions)
ActiveRecord::Base.send :include, AnnotationBase::Association
