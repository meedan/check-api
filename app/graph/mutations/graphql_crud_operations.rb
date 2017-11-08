class GraphqlCrudOperations
  def self.safe_save(obj, attrs, parents = [])
    attrs.each do |key, value|
      obj.send("#{key}=", value)
    end
    obj.disable_es_callbacks = Rails.env.to_s == 'test'
    obj.save!

    name = obj.class_name.underscore
    ret = { name.to_sym => obj }

    parents.each do |parent_name|
      child, parent = obj, obj.send(parent_name)
      unless parent.nil?
        parent.no_cache = true if parent.respond_to?(:no_cache)
        ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(child, parent) unless parent_name == 'public_team'
        ret[parent_name.to_sym] = parent
      end
    end

    if obj.is_a?(Team) && User.current.present?
      ret["team_userEdge".to_sym] = GraphQL::Relay::Edge.between(obj.reload.team_user, User.current.reload)
      ret[:user] = User.current
    end

    ret[:affectedIds] = obj.affected_ids if obj.respond_to?(:affected_ids)
    ret[:affectedId] = obj.graphql_id if obj.is_a?(ProjectMedia)

    ret
  end

  def self.create(type, inputs, ctx, parents = [])
    klass = type.camelize

    obj = klass.constantize.new
    obj.file = ctx[:file] if !ctx[:file].blank?

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId"
      memo
    end

    self.safe_save(obj, attrs, parents)
  end

  def self.update(_type, inputs, ctx, parents = [])
    obj = CheckGraphql.object_from_id(inputs[:id], ctx)
    obj.file = ctx[:file] if !ctx[:file].blank?
    obj = obj.load if obj.is_a?(Annotation)

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
      memo
    end

    self.safe_save(obj, attrs, parents)
  end

  def self.destroy(inputs, ctx, parents = [])
    type, id = CheckGraphql.decode_id(inputs[:id])
    obj = type.constantize.find(id)
    obj = obj.load if obj.respond_to?(:load)
    obj.disable_es_callbacks = (Rails.env.to_s == 'test') if obj.respond_to?(:disable_es_callbacks)
    obj.respond_to?(:destroy_later) ? obj.destroy_later(ctx[:ability]) : obj.destroy

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
        'bool' => types.Boolean,
        'json' => JsonStringType
      }

      name "#{action.camelize}#{type.camelize}"

      fields.each do |field_name, field_type|
        input_field field_name, mapping[field_type]
      end

      klass = "#{type.camelize}Type".constantize
      return_field type.to_sym, klass

      return_field(:affectedIds, types[types.ID]) if type.to_s == 'team'
      return_field(:affectedId, types.ID) if type.to_s == 'project_media'

      if type.to_s == 'team'
        return_field(:team_userEdge, TeamUserType.edge_type)
        return_field(:user, UserType)
      end

      parents.each do |parent|
        return_field "#{type}Edge".to_sym, klass.edge_type
        parentclass = parent =~ /^check_search_/ ? 'CheckSearch' : parent.gsub(/_was$/, '').camelize
        return_field parent.to_sym, "#{parentclass}Type".constantize
      end

      resolve -> (_root, inputs, ctx) {
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
        parentclass = parent =~ /^check_search_/ ? 'CheckSearch' : parent.gsub(/_was$/, '').camelize
        return_field parent.to_sym, "#{parentclass}Type".constantize
      end

      resolve -> (_root, inputs, ctx) {
        GraphqlCrudOperations.destroy(inputs, ctx, parents)
      }
    end
  end

  def self.define_crud_operations(type, create_fields, update_fields = {}, parents = [])
    update_fields = create_fields if update_fields.empty?
    [GraphqlCrudOperations.define_create(type, create_fields, parents), GraphqlCrudOperations.define_update(type, update_fields, parents), GraphqlCrudOperations.define_destroy(type, parents)]
  end

  def self.define_default_type(&block)
    GraphQL::ObjectType.define do
      global_id_field :id

      field :permissions, types.String do
        resolve -> (obj, _args, ctx) {
          obj.permissions(ctx[:ability])
        }
      end

      field :created_at, types.String do
        resolve -> (obj, _args, _ctx) {
          obj.created_at.to_i.to_s if obj.respond_to?(:created_at)
        }
      end

      field :updated_at, types.String do
        resolve -> (obj, _args, _ctx) {
          obj.updated_at.to_i.to_s if obj.respond_to?(:updated_at)
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

  def self.field_published
    proc do |_classname|
      field :published do
        type types.String

        resolve ->(obj, _args, _ctx) {
          obj.created_at.to_i.to_s
        }
      end
    end
  end

  def self.field_annotations
    proc do |_classname|
      connection :annotations, -> { AnnotationType.connection_type } do
        argument :annotation_type, !types.String

        resolve ->(obj, args, _ctx) {
          obj.get_annotations(args['annotation_type'].split(',').map(&:strip))
        }
      end
    end
  end

  def self.field_annotations_count
    proc do |_classname|
      field :annotations_count do
        type types.Int
        argument :annotation_type, !types.String

        resolve ->(obj, args, _ctx) {
          obj.get_annotations(args['annotation_type'].split(',').map(&:strip)).count
        }
      end
    end
  end

  def self.field_log
    proc do |_classname|
      connection :log, -> { VersionType.connection_type } do
        resolve ->(obj, _args, _ctx) {
          obj.get_versions_log.reverse
        }
      end
    end
  end

  def self.field_log_count
    proc do |_classname|
      field :log_count do
        type types.Int

        resolve ->(obj, _args, _ctx) {
          obj.get_versions_log_count
        }
      end
    end
  end

  def self.project_association
    proc do |class_name, field_name, type|
      field field_name do
        type type
        description 'Information about a project association, The argument should be given like this: "project_association_id,project_id,team_id"'
        argument :ids, !types.String
        resolve -> (_obj, args, ctx) do
          objid, pid, tid = args['ids'].split(',').map(&:to_i)
          tid = (Team.current.blank? && tid.nil?) ? 0 : (tid || Team.current.id)
          project = Project.where(id: pid, team_id: tid).last
          pid = project.nil? ? 0 : project.id
          objid = class_name.belonged_to_project(objid, pid) || 0
          GraphqlCrudOperations.load_if_can(class_name, objid, ctx)
        end
      end
    end
  end

  def self.define_annotation_fields
    [:annotation_type, :annotated_id, :annotated_type, :content, :dbid]
  end

  def self.define_annotation_type(type, fields = {}, &block)
    GraphQL::ObjectType.define do
      name type.capitalize

      interfaces [NodeIdentification.interface]

      field :id, !types.ID do
        resolve -> (annotation, _args, _ctx) {
          annotation.relay_id(type)
        }
      end

      GraphqlCrudOperations.define_annotation_fields.each { |name| field name, types.String }

      field :permissions, types.String do
        resolve -> (annotation, _args, ctx) {
          annotation.permissions(ctx[:ability], annotation.annotation_type_class)
        }
      end

      field :created_at, types.String do resolve -> (annotation, _args, _ctx) { annotation.created_at.to_i.to_s } end

      field :updated_at, types.String do resolve -> (annotation, _args, _ctx) { annotation.updated_at.to_i.to_s } end

      fields.each { |name, _field_type| field name, types.String }

      connection :medias, -> { ProjectMediaType.connection_type } do
        resolve ->(annotation, _args, _ctx) {
          annotation.entity_objects
        }
      end
      instance_exec :annotator, AnnotatorType, &GraphqlCrudOperations.annotation_fields
      instance_exec :version, VersionType, &GraphqlCrudOperations.annotation_fields

      instance_eval(&block) if block_given?
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
    klass.find_if_can(id, ctx[:ability])
  end
end

JsonStringType = GraphQL::ScalarType.define do
  name "JsonStringType"
  coerce_input -> (val, _ctx) { JSON.parse(val) }
  coerce_result -> (val, _ctx) { val.as_json }
end
