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
    def item
      self.item_type.constantize.find(self.item_id)
    end
    def project_media
      self.item.project_media if self.item.respond_to?(:project_media)
    end
    def source
      self.item.source if self.item.respond_to?(:source)
    end
  end
end

PaperTrail::Version.send(:include, PaperTrail::CheckdeskExtensions)
ActiveRecord::Base.send :include, AnnotationBase::Association
