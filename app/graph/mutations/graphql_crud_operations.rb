class GraphqlCrudOperations
  def self.type_mapping
    proc do |_classname|
      {
        'str' => types.String,
        '!str' => !types.String,
        'int' => types.Int,
        '!int' => !types.Int,
        'id' => types.ID,
        '!id' => !types.ID,
        'bool' => types.Boolean,
        'json' => JsonStringType
      }.freeze
    end
  end

  def self.safe_save(obj, attrs, parents = [], inputs = {})
    raise "This operation must be done by a signed-in user" if User.current.nil?
    attrs.each do |key, value|
      method = key == 'clientMutationId' ? 'client_mutation_id=' : "#{key}="
      obj.send(method, value) if obj.respond_to?(method)
    end
    obj.disable_es_callbacks = Rails.env.to_s == 'test'
    obj.save_with_version!

    name = obj.class_name.underscore
    { name.to_sym => obj }.merge(GraphqlCrudOperations.define_returns(obj, inputs, parents))
  end

  def self.define_returns(obj, _inputs, parents)
    ret = {}
    name = obj.class_name.underscore
    parents.each do |parent_name|
      child, parent = obj, obj.send(parent_name)
      parent = obj.version_object if parent_name == 'version'
      unless parent.nil?
        parent.no_cache = true if parent.respond_to?(:no_cache)
        ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(child, parent) if !['related_to', 'public_team', 'version'].include?(parent_name)
        ret[parent_name.to_sym] = parent
      end
    end
    ret.merge(GraphqlCrudOperations.define_conditional_returns(obj))
  end

  def self.define_conditional_returns(obj)
    ret = {}

    if obj.is_a?(Team) && User.current.present?
      team_user = obj.reload.team_user
      ret["team_userEdge".to_sym] = GraphQL::Relay::Edge.between(team_user, User.current.reload) unless team_user.nil?
      ret[:user] = User.current
    end

    if [Comment, Task, Dynamic].include?(obj.class)
      version = obj.version_object
      ret["versionEdge".to_sym] = GraphQL::Relay::Edge.between(version, obj.annotated) unless version.nil?
    end

    ret[:affectedId] = obj.graphql_id if obj.is_a?(ProjectMedia)

    ret
  end

  def self.create(type, inputs, ctx, parents = [])
    klass = type.camelize

    obj = klass.constantize.new
    obj.is_being_created = true if obj.respond_to?(:is_being_created)
    obj.file = ctx[:file] if !ctx[:file].blank?

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key]
      memo
    end
    attrs['annotation_type'] = type.gsub(/^dynamic_annotation_/, '') if type =~ /^dynamic_annotation_/

    self.safe_save(obj, attrs, parents)
  end

  def self.crud_operation(operation, obj, inputs, ctx, parents, _returns = {})
    self.send("#{operation}_from_single_id", inputs[:id] || obj.graphql_id, inputs, ctx, parents) if inputs[:id] || obj
  end

  def self.object_from_id_and_context(id, ctx)
    obj = CheckGraphql.object_from_id(id, ctx)
    obj = obj.load if obj.is_a?(Annotation)
    obj
  end

  def self.update_from_single_id(id, inputs, ctx, parents)
    obj = self.object_from_id_and_context(id, ctx)
    obj.file = ctx[:file] if !ctx[:file].blank?

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == 'id'
      memo
    end

    self.safe_save(obj, attrs, parents, inputs)
  end

  def self.update(_type, inputs, ctx, parents = [])
    obj = self.object_from_id_and_context(inputs[:id], ctx)
    returns = obj.nil? ? {} : GraphqlCrudOperations.define_returns(obj, inputs, parents)
    self.crud_operation('update', obj, inputs, ctx, parents, returns)
  end

  def self.destroy_from_single_id(graphql_id, inputs, ctx, parents)
    obj = self.object_from_id(graphql_id)
    obj.keep_completed_tasks = inputs[:keep_completed_tasks] if obj.is_a?(TeamTask)
    if obj.is_a?(Relationship)
      obj.add_to_project_id = inputs[:add_to_project_id]
      obj.archive_target = inputs[:archive_target]
    end
    obj.items_destination_project_id = inputs[:items_destination_project_id] if obj.is_a?(Project)
    obj.disable_es_callbacks = (Rails.env.to_s == 'test') if obj.respond_to?(:disable_es_callbacks)
    obj.respond_to?(:destroy_later) ? obj.destroy_later(ctx[:ability]) : ApplicationRecord.connection_pool.with_connection { obj.destroy }

    deleted_id = obj.respond_to?(:graphql_deleted_id) ? obj.graphql_deleted_id : graphql_id
    ret = { deletedId: deleted_id }

    parents.each { |parent| ret[parent.to_sym] = obj.send(parent) }

    ret
  end

  def self.object_from_id(graphql_id)
    type, id = CheckGraphql.decode_id(graphql_id)
    obj = type.constantize.where(id: id).last
    obj = obj.load if obj.respond_to?(:load)
    obj
  end

  def self.object_from_id_if_can(graphql_id, ability)
    type, id = CheckGraphql.decode_id(graphql_id)
    obj = type.constantize.find_if_can(id, ability)
    obj = obj.load if obj.respond_to?(:load)
    obj
  end

  def self.destroy(_type, inputs, ctx, parents = [])
    returns = {}
    obj = self.object_from_id(inputs[:id])
    unless obj.nil?
      parents.each do |parent|
        parent_obj = obj.send(parent)
        returns[parent.to_sym] = parent_obj
      end
    end
    self.crud_operation('destroy', obj, inputs, ctx, parents, returns)
  end

  def self.define_create(type, create_fields, parents = [])
    self.define_create_or_update('create', type, create_fields, parents)
  end

  def self.define_update(type, update_fields, parents = [])
    self.define_create_or_update('update', type, update_fields, parents)
  end

  def self.define_create_or_update(action, type, fields, parents = [])
    GraphQL::Relay::Mutation.define do
      mapping = instance_exec(&GraphqlCrudOperations.type_mapping)
      name "#{action.camelize}#{type.camelize}"

      if action == 'update'
        input_field :id, types.ID
      end
      fields.each { |field_name, field_type| input_field field_name, mapping[field_type] }

      klass = "#{type.camelize}Type".constantize
      return_field type.to_sym, klass

      return_field(:affectedId, types.ID) if type.to_s == 'project_media'

      if type.to_s == 'team'
        return_field(:team_userEdge, TeamUserType.edge_type)
        return_field(:user, UserType)
      end

      if type =~ /^dynamic_annotation_/
        return_field :dynamic, DynamicType
        return_field :dynamicEdge, DynamicType.edge_type
      end

      return_field("versionEdge".to_sym, VersionType.edge_type) if ['task', 'comment'].include?(type.to_s) || type =~ /dynamic/

      return_field type.to_sym, klass
      return_field "#{type}Edge".to_sym, klass.edge_type
      GraphqlCrudOperations.define_parent_returns(parents).each{ |field_name, field_class| return_field(field_name, field_class) }

      resolve -> (_root, inputs, ctx) { GraphqlCrudOperations.send(action, type, inputs, ctx, parents) }
    end
  end

  def self.define_bulk_update_or_destroy(update_or_destroy, klass, fields, parents)
    GraphQL::Relay::Mutation.define do
      mapping = instance_exec(&GraphqlCrudOperations.type_mapping)
      name "#{update_or_destroy.to_s.capitalize}#{klass.name.pluralize}"

      input_field :ids, !types[types.ID]
      fields.each { |field_name, field_type| input_field field_name, mapping[field_type] }

      return_field :ids, types[types.ID]
      GraphqlCrudOperations.define_parent_returns(parents).each{ |field_name, field_class| return_field(field_name, field_class) }

      resolve -> (_root, inputs, ctx) {
        if inputs[:ids].size > 10000
          raise I18n.t(:bulk_operation_limit_error, limit: 10000)
        end

        sql_ids = []
        processed_ids = []
        inputs[:ids].to_a.each do |graphql_id|
          type, id = CheckGraphql.decode_id(graphql_id)
          if type == klass.name
            sql_ids << id
            processed_ids << graphql_id
          end
        end

        ability = ctx[:ability] || Ability.new
        if ability.can?("bulk_#{update_or_destroy}".to_sym, klass.new(team: Team.current))
          filtered_inputs = inputs.to_h.reject{ |k, _v| ['ids', 'clientMutationId'].include?(k.to_s) }.with_indifferent_access
          method_mapping = {
            update: :bulk_update,
            destroy: :bulk_destroy
          }
          method = method_mapping[update_or_destroy.to_sym]
          result = klass.send(method, sql_ids, filtered_inputs, Team.current)
          { ids: processed_ids }.merge(result)
        else
          raise CheckPermissions::AccessDenied, I18n.t(:permission_error)
        end
      }
    end
  end

  def self.define_bulk_update(klass, fields, parents)
    self.define_bulk_update_or_destroy(:update, klass, fields, parents)
  end

  def self.define_bulk_create(klass, fields, parents)
    input_type = "Create#{klass.name.pluralize}BulkInput"
    definition = GraphQL::InputObjectType.define do
      mapping = instance_exec(&GraphqlCrudOperations.type_mapping)
      name(input_type)
      fields.each { |field_name, field_type| argument field_name, mapping[field_type] }
    end
    Object.const_set input_type, definition

    GraphQL::Relay::Mutation.define do
      name "Create#{klass.name.pluralize}"

      input_field :inputs, types[input_type.constantize]

      GraphqlCrudOperations.define_parent_returns(parents).each{ |field_name, field_class| return_field(field_name, field_class) }

      resolve -> (_root, input, ctx) {
        if input[:inputs].size > 10000
          raise I18n.t(:bulk_operation_limit_error, limit: 10000)
        end

        ability = ctx[:ability] || Ability.new
        if ability.can?(:bulk_create, klass.new(team: Team.current))
          klass.bulk_create(input['inputs'], Team.current)
        else
          raise CheckPermissions::AccessDenied, I18n.t(:permission_error)
        end
      }
    end
  end

  def self.define_destroy(type, parents = [])
    GraphQL::Relay::Mutation.define do
      name "Destroy#{type.camelize}"

      input_field :id, types.ID

      input_field(:keep_completed_tasks, types.Boolean) if type == 'team_task'

      if type == 'relationship'
        input_field(:add_to_project_id, types.Int)
        input_field(:archive_target, types.Int)
      end

      input_field(:items_destination_project_id, types.Int) if type == 'project'

      return_field :deletedId, types.ID

      GraphqlCrudOperations.define_parent_returns(parents).each{ |field_name, field_class| return_field(field_name, field_class) }

      resolve -> (_root, inputs, ctx) { GraphqlCrudOperations.destroy(type, inputs, ctx, parents) }
    end
  end

  def self.define_parent_returns(parents = [])
    fields = {}
    parents.each do |parent|
      parentclass = parent =~ /^check_search_/ ? 'CheckSearch' : parent.gsub(/_was$/, '').camelize
      parentclass = 'ProjectMedia' if ['related_to', 'source_project_media', 'target_project_media'].include?(parent)
      parentclass = 'TagText' if parent == 'tag_text_object'
      parentclass = 'Project' if parent == 'previous_default_project'
      fields[parent.to_sym] = "#{parentclass}Type".constantize
    end
    fields
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

  def self.field_published
    proc do |_classname|
      field :published do
        type types.String

        resolve ->(obj, _args, _ctx) { obj.created_at.to_i.to_s }
      end
    end
  end

  def self.field_annotations
    proc do |_classname|
      connection :annotations, -> { AnnotationUnion.connection_type } do
        argument :annotation_type, !types.String

        resolve ->(obj, args, _ctx) { obj.get_annotations(args['annotation_type'].split(',').map(&:strip)) }
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
        argument :event_types, types[types.String]
        argument :field_names, types[types.String]
        argument :annotation_types, types[types.String]
        argument :who_dunnit, types[types.String]
        argument :include_related, types.Boolean

        resolve ->(obj, args, _ctx) {
          obj.get_versions_log(args['event_types'], args['field_names'], args['annotation_types'], args['who_dunnit'], args['include_related'])
        }
      end
    end
  end

  def self.field_tasks
    proc do |_classname|
      connection :tasks, -> { TaskType.connection_type } do
        argument :fieldset, types.String

        resolve ->(obj, args, _ctx) {
          tasks = Task.where(annotation_type: 'task', annotated_type: obj.class.name, annotated_id: obj.id)
          tasks = tasks.from_fieldset(args['fieldset']) unless args['fieldset'].blank?
          # Order tasks by order field
          ids = tasks.to_a.sort_by{ |task| task.order ||= 0 }.map(&:id)
          values = []
          ids.each_with_index do |id, i|
            values << "(#{id}, #{i})"
          end
          return tasks if values.empty?
          joins = ActiveRecord::Base.send(:sanitize_sql_array,
            ["JOIN (VALUES %s) AS x(value, order_number) ON %s.id = x.value", values.join(', '), 'annotations'])
          tasks.joins(joins).order('x.order_number')
        }
      end
    end
  end

  def self.archived_count
    proc do |name|
      field name do
        type types.Int

        resolve ->(team, _args, _ctx) {
          (team.private && (!User.current || (!User.current.is_admin && TeamUser.where(team_id: team.id, user_id: User.current.id).last.nil?))) ? 0 : team.send(name)
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

  def self.define_annotation_fields
    [:annotation_type, :annotated_id, :annotated_type, :content, :dbid]
  end

  def self.define_annotation_mutation_fields
    {
      fragment: 'str',
      annotated_id: 'str',
      annotated_type: 'str'
    }
  end

  def self.define_annotation_type(type, fields = {}, &block)
    GraphQL::ObjectType.define do
      name type.capitalize

      interfaces [NodeIdentification.interface]

      field :id, !types.ID do resolve -> (annotation, _args, _ctx) { annotation.relay_id(type) } end

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

      connection :assignments, -> { UserType.connection_type } do
        resolve ->(annotation, _args, _ctx) {
          annotation.assigned_users
        }
      end

      connection :annotations, -> { AnnotationUnion.connection_type } do
        argument :annotation_type, !types.String
        resolve ->(annotation, args, _ctx) {
          Annotation.where(annotation_type: args['annotation_type'], annotated_type: ['Annotation', annotation.annotation_type.camelize], annotated_id: annotation.id)
        }
      end

      field :locked, types.Boolean

      field :project, ProjectType

      field :team, TeamType

      field :file_data, JsonStringType

      field :data, JsonStringType

      field :parsed_fragment, JsonStringType

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
