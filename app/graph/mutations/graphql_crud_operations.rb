class GraphqlCrudOperations
  def self.safe_save(obj, attrs, parents = [])
    attrs.each do |key, value|
      obj.send("#{key}=", value)
    end
    obj.save!

    name = obj.class_name.underscore
    ret = { name.to_sym => obj }

    parents.each do |parent_name|
      child, parent = obj, obj.send(parent_name)
      unless parent.nil?
        parent.no_cache = true
        ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(child, parent)
        ret[parent_name.to_sym] = parent
      end
    end

    ret
  end

  def self.create(type, inputs, ctx, parents = [])
    klass = type.camelize

    obj = klass.constantize.new
    obj.file = ctx[:file] if type == 'project_media' && !ctx[:file].blank?

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId"
      memo
    end

    self.safe_save(obj, attrs, parents)
  end

  def self.update(_type, inputs, ctx, parents = [])
    obj = NodeIdentification.object_from_id(inputs[:id], ctx)

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
      memo
    end

    self.safe_save(obj, attrs, parents)
  end

  def self.destroy(inputs, _ctx, parents = [])
    type, id = NodeIdentification.from_global_id(inputs[:id])
    obj = type.constantize.find(id)
    obj.destroy

    ret = { deletedId: inputs[:id] }

    parents.each { |parent| ret[parent.to_sym] = obj.send(parent) }

    ret
  end

  def self.define_create(type, create_fields, parents = [])
    self.define_create_or_update('create', type, create_fields, parents)
  end

  def self.define_update(type, update_fields, parents = [])
    self.define_create_or_update('update', type, update_fields, parents)
  end

  def self.define_create_or_update(action, type, fields, parents = [])
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

      parents.each do |parent|
        return_field "#{type}Edge".to_sym, klass.edge_type
        return_field parent.to_sym, "#{parent.camelize}Type".constantize
      end

      resolve -> (inputs, ctx) {
        GraphqlCrudOperations.send(action, type, inputs, ctx, parents)
      }
    end
  end

  def self.define_destroy(type, parents = [])
    GraphQL::Relay::Mutation.define do
      name "Destroy#{type.camelize}"

      input_field :id, !types.ID

      return_field :deletedId, types.ID
      parents.each do |parent|
        return_field parent.to_sym, "#{parent.camelize}Type".constantize
      end

      resolve -> (inputs, ctx) {
        GraphqlCrudOperations.destroy(inputs, ctx, parents)
      }
    end
  end

  def self.define_crud_operations(type, create_fields, update_fields = {}, parents = [])
    update_fields = create_fields if update_fields.empty?
    [
      GraphqlCrudOperations.define_create(type, create_fields, parents),
      GraphqlCrudOperations.define_update(type, update_fields, parents),
      GraphqlCrudOperations.define_destroy(type, parents)
    ]
  end

  def self.define_default_type(&block)
    GraphQL::ObjectType.define do
      field :permissions, types.String do
        resolve -> (obj, _args, ctx) {
          obj.permissions(ctx[:ability])
        }
      end

      instance_eval(&block)
    end
  end

  def self.field_verification_statuses
    proc do |classname|
      field :verification_statuses do
        type types.String

        resolve ->(_obj, _args, _ctx) {
          team = Team.current || Team.new
          team.verification_statuses(classname)
        }
      end
    end
  end

  def self.define_annotation_fields
    [:annotation_type, :updated_at, :created_at,
     :annotated_id, :annotated_type, :content, :dbid ]
  end

  def self.define_annotation_type(type, fields = {})
    GraphQL::ObjectType.define do
      name type.capitalize

      interfaces [NodeIdentification.interface]

      field :id, !types.ID do
        resolve -> (annotation, _args, _ctx) {
          annotation.relay_id(type)
        }
      end

      GraphqlCrudOperations.define_annotation_fields.each do |name|
        field name, types.String
      end

      field :permissions, types.String do
        resolve -> (annotation, _args, ctx) {
          klass = begin
                    annotation.annotation_type.camelize.constantize
                  rescue NameError
                    Dynamic
                  end
          annotation.permissions(ctx[:ability], klass)
        }
      end

      fields.each do |name, _field_type|
        field name, types.String
      end

      connection :medias, -> { ProjectMediaType.connection_type } do
        resolve ->(annotation, _args, _ctx) {
          annotation.entity_objects
        }
      end
      instance_exec :annotator, AnnotatorType, &GraphqlCrudOperations.annotation_fields
      instance_exec :version, VersionType, &GraphqlCrudOperations.annotation_fields
    end
  end

  def self.annotation_fields
    proc do |name, field_type = types.String, method = nil|
      field name do
        type field_type

        resolve -> (annotation, _args, _ctx) {
          annotation.send(method.blank? ? name : method)
        }
      end
    end
  end

  def self.load_if_can(klass, id, ctx)
    obj = klass.find_if_can(id, ctx[:ability])
    obj
  end
end
