class GraphqlCrudOperations
  def self.safe_save(obj, attrs)
    attrs.each do |key, value|
      obj.send("#{key}=", value)
    end
    obj.save
    obj
  end

  def self.create(type, inputs, ctx)
    obj = type.camelize.constantize.new
    obj.current_user = ctx[:current_user]
    
    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId"
      memo
    end
    
    obj = self.safe_save(obj, attrs)

    { type.to_sym => obj }
  end

  def self.update(type, inputs, ctx)
    obj = NodeIdentification.object_from_id(inputs[:id], ctx)
    obj.current_user = ctx[:current_user]
    
    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
      memo
    end

    obj = self.safe_save(obj, attrs)

    { type.to_sym => obj }
  end

  def self.destroy(inputs, ctx)
    obj = NodeIdentification.object_from_id(inputs[:id], ctx)
    obj.destroy
    { deletedId: inputs[:id] }
  end

  def self.define_create(type, create_fields)
    self.define_create_or_update('create', type, create_fields)
  end

  def self.define_update(type, update_fields)
    self.define_create_or_update('update', type, update_fields)
  end

  def self.define_create_or_update(action, type, fields)
    GraphQL::Relay::Mutation.define do
      mapping = {
        'str'  => types.String,
        '!str' => !types.String,
        'int'  => types.Int,
        '!int' => !types.Int,
        'id'   => types.ID,
        '!id'  => !types.ID,
        'bool' => types.Boolean
      }

      name "#{action.camelize}#{type.camelize}"
   
      fields.each do |field_name, field_type|
        input_field field_name, mapping[field_type]
      end

      return_field type.to_sym, "#{type.camelize}Type".constantize

      resolve -> (inputs, ctx) {
        GraphqlCrudOperations.send(action, type, inputs, ctx)
      }
    end
  end

  def self.define_destroy(type)
    GraphQL::Relay::Mutation.define do
      name "Destroy#{type.camelize}"

      input_field :id, !types.ID

      return_field :deletedId, types.ID

      resolve -> (inputs, ctx) {
        GraphqlCrudOperations.destroy(inputs, ctx)
      }
    end
  end

  def self.define_crud_operations(type, create_fields, update_fields = {})
    update_fields = create_fields if update_fields.empty?
    [
      GraphqlCrudOperations.define_create(type, create_fields),
      GraphqlCrudOperations.define_update(type, update_fields),
      GraphqlCrudOperations.define_destroy(type)
    ]
  end

  def self.define_annotation_type(type, fields = {})
    GraphQL::ObjectType.define do
      name type.capitalize
      description "#{type.capitalize} type"
    
      interfaces [NodeIdentification.interface]
    
      field :id, field: GraphQL::Relay::GlobalIdField.new(type.capitalize)
      field :annotation_type, types.String
      field :updated_at, types.String
      field :created_at, types.String
      field :context_id, types.String
      field :context_type, types.String
      field :annotated_id, types.String
      field :annotated_type, types.String

      mapping = {
        'str' => types.String
      }

      fields.each do |name, type|
        field name, mapping[type]
      end
      
      field :annotator do
        type UserType
    
        resolve -> (annotation, _args, _ctx) {
          annotation.annotator
        }
      end
    end
  end
end
