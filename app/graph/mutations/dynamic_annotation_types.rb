# TODO Do we really need to expose each dynamic annotation type as a GraphQL type?
DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
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
      Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('dynamic_annotation_#{type}', create_fields, update_fields, parents, false) unless defined? Create
    end

    DynamicAnnotation#{klass}Type = GraphqlCrudOperations.define_annotation_type('dynamic_annotation_#{type}', {}) do
    end unless defined? DynamicAnnotation#{klass}Type
  TES
end
