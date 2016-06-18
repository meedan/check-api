PaperTrail.config.track_associations = false
PaperTrail.serializer = PaperTrail::Serializers::JSON

module PaperTrail
  module AttributeSerializers
    class CastAttributeSerializer
      def initialize(klass)
        @klass = klass
      end
      
      def serialize(attr, val)
        val.to_s
      end
                      
      def deserialize(attr, val)
        val
      end
    end
  end

  module CheckdeskExtensions
    def item
      self.item_type.constantize.find(self.item_id)
    end
  end
end

PaperTrail::Version.send(:include, PaperTrail::CheckdeskExtensions)
ActiveRecord::Base.send :include, AnnotationBase::Association
