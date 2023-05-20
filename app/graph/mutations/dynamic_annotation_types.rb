module DynamicAnnotation::AnnotationTypeManager
  def self.define_type(type)
    klass = type.camelize
    Object.class_eval <<-TES
      DynamicAnnotation#{klass} = Dynamic unless defined?(DynamicAnnotation#{klass})

      module DynamicAnnotation#{klass}Mutations
        fields = {}
        ['annotated_id', 'annotated_type', 'set_attribution', 'fragment', 'action', 'action_data'].each do |name|
          fields[name] = 'str'
        end

        create_fields = fields.merge({ set_fields: '!str' })

        update_fields = fields.merge({
          set_fields: 'str',
          lock_version: 'int',
          assigned_to_ids: 'str',
          locked: 'bool'
        })

        parents = ['project_media', 'source', 'project']
        Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('dynamic_annotation_#{type}', create_fields, update_fields, parents) unless defined? Create
      end

      class Types::DynamicAnnotation#{klass}Type < Types::AnnotationObject
        field :lock_version, Integer, null: true
      end unless defined? Types::DynamicAnnotation#{klass}Type
    TES
  end
end
