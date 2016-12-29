class GraphqlCrudOperations
  def self.safe_save(obj, attrs, parents = [])
    attrs.each do |key, value|
      obj.send("#{key}=", value)
    end
    obj.save!

    name = obj.class.name.underscore
    ret = { name.to_sym => obj }

    parents.each do |parent_name|
      child, parent = obj, obj.send(parent_name)
      unless parent.nil?
        parent.no_cache = true
        parent.project_id = child.context_id if parent_name.to_s == 'media' && child.context_type == 'Project' && parent.respond_to?(:project_id)
        ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(child, parent)
        ret[parent_name.to_sym] = parent
      end
    end

    ret
  end

  def self.create(type, inputs, ctx, parents = [])
    obj = type.camelize.constantize.new
    obj.current_user = ctx[:current_user]
    obj.context_team = ctx[:context_team]
    obj.origin = ctx[:origin] if obj.respond_to?('origin=')

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

  def self.destroy(inputs, ctx, parents = [])
    type, id = NodeIdentification.from_global_id(inputs[:id])
    obj = type.constantize.find(id)
    obj.current_user = ctx[:current_user]
    obj.context_team = ctx[:context_team]
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
          obj.current_user = ctx[:current_user]
          obj.project_id ||= ctx[:context_project].id if obj.is_a?(Media) && ctx[:context_project].present?
          obj.permissions(ctx[:ability])
        }
      end

      instance_eval(&block)
    end
  end

  def self.field_with_context
    proc do |name, field_type = types.String, method = nil|
      field name do
        type field_type

        resolve -> (project_media, _args, _ctx) {
          call_method_from_context(project_media, method.blank? ? name : method)
        }
      end
    end
  end

  def self.field_verification_statuses
    proc do |classname|
      field :verification_statuses do
        type types.String

        resolve ->(_obj, _args, ctx) {
          team = ctx[:context_team] || Team.new
          team.verification_statuses(classname)
        }
      end
    end
  end

  def self.define_annotation_fields
    [:annotation_type, :updated_at, :created_at,
     :context_id, :context_type, :annotated_id,
     :annotated_type, :content, :dbid ]
  end

  def self.define_annotation_type(type, fields = {})
    GraphQL::ObjectType.define do
      name type.capitalize

      interfaces [NodeIdentification.interface]

      field :id, field: GraphQL::Relay::GlobalIdField.new(type.capitalize)

      GraphqlCrudOperations.define_annotation_fields.each do |name|
        field name, types.String
      end

      field :permissions, types.String do
        resolve -> (annotation, _args, ctx) {
          annotation.current_user = ctx[:current_user]
          annotation.permissions(ctx[:ability], annotation.annotation_type.camelize.constantize)
        }
      end

      fields.each do |name, _field_type|
        field name, types.String
      end

      field :annotator do
        type AnnotatorType

        resolve -> (annotation, _args, _ctx) {
          annotation.annotator
        }
      end

      connection :medias, -> { MediaType.connection_type } do
        resolve ->(annotation, _args, _ctx) {
          annotation.entity_objects
        }
      end
    end
  end

  def self.load_if_can(klass, id, ctx)
    obj = klass.find_if_can(id, ctx[:current_user], ctx[:context_team], ctx[:ability])
    obj.current_user = ctx[:current_user]
    obj.context_team = ctx[:context_team]
    obj
  end
end
