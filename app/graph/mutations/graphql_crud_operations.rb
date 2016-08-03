class GraphqlCrudOperations
  def self.safe_save(obj, attrs, parent = nil)
    attrs.each do |key, value|
      obj.send("#{key}=", value)
    end
    obj.save!
    
    name = obj.class.name.underscore
    ret = { name.to_sym => obj }
    
    unless parent.nil?
      sleep 1
      child, parent = obj, obj.send(parent)
      ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(child, parent)
      ret[:parent] = parent
    end

    ret
  end

  def self.create(type, inputs, ctx, parent = nil)
    obj = type.camelize.constantize.new
    obj.current_user = ctx[:current_user]
    
    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId"
      memo
    end
    
    self.safe_save(obj, attrs, parent)
  end

  def self.update(_type, inputs, ctx, parent = nil)
    obj = NodeIdentification.object_from_id(inputs[:id], ctx)
    obj.current_user = ctx[:current_user]
    
    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
      memo
    end

    self.safe_save(obj, attrs, parent)
  end

  def self.destroy(inputs, ctx, parent = nil)
    obj = NodeIdentification.object_from_id(inputs[:id], ctx)
    obj.destroy
    ret = { deletedId: inputs[:id] }

    ret[:parent] = obj.send(parent) unless parent.nil?

    ret
  end

  def self.define_create(type, create_fields, parent = nil)
    self.define_create_or_update('create', type, create_fields, parent)
  end

  def self.define_update(type, update_fields, parent = nil)
    self.define_create_or_update('update', type, update_fields, parent)
  end

  def self.define_create_or_update(action, type, fields, parent = nil)
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

      klass = "#{type.camelize}Type".constantize
      return_field type.to_sym, klass 

      unless parent.nil?
        return_field "#{type}Edge".to_sym, klass.edge_type
        return_field :parent, "#{parent.camelize}Type".constantize
      end

      resolve -> (inputs, ctx) {
        GraphqlCrudOperations.send(action, type, inputs, ctx, parent)
      }
    end
  end

  def self.define_destroy(type, parent = nil)
    GraphQL::Relay::Mutation.define do
      name "Destroy#{type.camelize}"

      input_field :id, !types.ID

      return_field :deletedId, types.ID
      unless parent.nil?
        return_field :parent, "#{parent.camelize}Type".constantize
      end

      resolve -> (inputs, ctx) {
        GraphqlCrudOperations.destroy(inputs, ctx, parent)
      }
    end
  end

  def self.define_crud_operations(type, create_fields, update_fields = {}, parent = nil)
    update_fields = create_fields if update_fields.empty?
    [
      GraphqlCrudOperations.define_create(type, create_fields, parent),
      GraphqlCrudOperations.define_update(type, update_fields, parent),
      GraphqlCrudOperations.define_destroy(type, parent)
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
      field :content, types.String

      mapping = {
        'str' => types.String
      }

      fields.each do |name, field_type|
        field name, mapping[field_type]
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
