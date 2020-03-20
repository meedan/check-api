DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
  klass = type.camelize
  Object.class_eval <<-TES
    DynamicAnnotation#{klass} = Dynamic unless defined?(DynamicAnnotation#{klass})

    module DynamicAnnotation#{klass}Mutations
      fields = { action: 'str', action_data: 'str' }
      ['annotated_id', 'annotated_type', 'set_attribution'].each do |name|
        fields[name] = 'str'
      end

      create_fields = fields.merge({ set_fields: '!str' })

      update_fields = fields.merge({
        set_fields: 'str',
        lock_version: 'int',
        assigned_to_ids: 'str',
        locked: 'bool'
      })

      parents = ['project_media', 'project_source', 'source', 'project']
      Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('dynamic_annotation_#{type}', create_fields, update_fields, parents) unless defined? Create
    end

    DynamicAnnotation#{klass}Type = GraphqlCrudOperations.define_annotation_type('dynamic_annotation_#{type}', {}) do
      field :lock_version, types.Int
    end unless defined? DynamicAnnotation#{klass}Type
  TES
end
