class GraphqlCrudOperations
  def self.type_mapping
    proc do |_classname|
      {
        "str" => types.String,
        "!str" => !types.String,
        "int" => types.Int,
        "!int" => !types.Int,
        "id" => types.ID,
        "!id" => !types.ID,
        "bool" => types.Boolean,
        "json" => Types::JsonString
      }.freeze
    end
  end

  def self.safe_save(obj, attrs, parents = [], inputs = {})
    if User.current.nil? && ApiKey.current.nil?
      raise "This operation must be done by a signed-in user"
    end
    attrs.each do |key, value|
      method = key == "clientMutationId" ? "client_mutation_id=" : "#{key}="
      obj.send(method, value) if obj.respond_to?(method)
    end
    obj.disable_es_callbacks = Rails.env.to_s == "test"
    obj.save_with_version!

    name = obj.class_name.underscore
    { name.to_sym => obj }.merge(
      GraphqlCrudOperations.define_returns(obj, inputs, parents)
    )
  end

  def self.define_returns(obj, _inputs, parents)
    ret = {}
    name = obj.class_name.underscore
    parents.each do |parent_name|
      child, parent = obj, obj.send(parent_name)
      parent = obj.version_object if parent_name == "version"
      unless parent.nil?
        parent.no_cache = true if parent.respond_to?(:no_cache)
        ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(
          child,
          parent
        ) if !%w[related_to public_team version].include?(parent_name)
        ret[parent_name.to_sym] = parent
      end
    end
    ret.merge(GraphqlCrudOperations.define_conditional_returns(obj))
  end

  def self.define_conditional_returns(obj)
    ret = {}

    if obj.is_a?(Team) && User.current.present?
      team_user = obj.reload.team_user
      ret["team_userEdge".to_sym] = GraphQL::Relay::Edge.between(
        team_user,
        User.current.reload
      ) unless team_user.nil?
      ret[:user] = User.current
    end

    if [Comment, Task, Dynamic].include?(obj.class)
      version = obj.version_object
      ret["versionEdge".to_sym] = GraphQL::Relay::Edge.between(
        version,
        obj.annotated
      ) unless version.nil?
    end

    ret[:affectedId] = obj.graphql_id if obj.is_a?(ProjectMedia)

    ret
  end

  def self.create(type, inputs, ctx, parents = [])
    klass = type.camelize

    obj = klass.constantize.new
    obj.is_being_created = true if obj.respond_to?(:is_being_created)
    obj.file = ctx[:file] if !ctx[:file].blank?

    attrs =
      inputs
        .keys
        .inject({}) do |memo, key|
          memo[key] = inputs[key]
          memo
        end
    attrs["annotation_type"] = type.gsub(/^dynamic_annotation_/, "") if type =~
      /^dynamic_annotation_/

    self.safe_save(obj, attrs, parents)
  end

  def self.crud_operation(operation, obj, inputs, ctx, parents, _returns = {})
    if inputs[:id] || obj
      self.send(
        "#{operation}_from_single_id",
        inputs[:id] || obj.graphql_id,
        inputs,
        ctx,
        parents
      )
    end
  end

  def self.object_from_id_and_context(id, ctx)
    obj = CheckGraphql.object_from_id(id, ctx)
    obj = obj.load if obj.is_a?(Annotation)
    obj
  end

  def self.update(_type, inputs, ctx, parents = [])
    obj = self.object_from_id_and_context(inputs[:id], ctx)
    returns =
      obj.nil? ? {} : GraphqlCrudOperations.define_returns(obj, inputs, parents)
    self.crud_operation("update", obj, inputs, ctx, parents, returns)
  end

  def self.object_from_id(graphql_id)
    type, id = CheckGraphql.decode_id(graphql_id)
    obj = nil
    unless type.blank? || id.blank?
      obj = type.constantize.where(id: id).last
      obj = obj.load if obj.respond_to?(:load)
    end
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
    self.crud_operation("destroy", obj, inputs, ctx, parents, returns)
  end

  def self.define_create_or_update(action, type, fields, parents = [])
    GraphQL::Relay::Mutation.define do
      mapping = instance_exec(&GraphqlCrudOperations.type_mapping)
      name "#{action.camelize}#{type.camelize}"

      input_field :id, types.ID if action == "update"
      fields.each do |field_name, field_type|
        input_field field_name, mapping[field_type]
      end

      klass = "Types::#{type.camelize}Type".constantize
      return_field type.to_sym, klass

      return_field(:affectedId, types.ID) if type.to_s == "project_media"

      if type.to_s == "team"
        return_field(:team_userEdge, Types::TeamUserType.edge_type)
        return_field(:user, Types::UserType)
      end

      if type =~ /^dynamic_annotation_/
        return_field :dynamic, Types::DynamicType
        return_field :dynamicEdge, Types::DynamicType.edge_type
      end

      if %w[task comment].include?(type.to_s) || type =~ /dynamic/
        return_field("versionEdge".to_sym, Types::VersionType.edge_type)
      end

      return_field type.to_sym, klass
      return_field "#{type}Edge".to_sym, klass.edge_type
      GraphqlCrudOperations
        .define_parent_returns(parents)
        .each do |field_name, field_class|
          return_field(field_name, field_class)
        end

      resolve ->(_root, inputs, ctx) {
                GraphqlCrudOperations.send(action, type, inputs, ctx, parents)
              }
    end
  end

  def self.define_bulk_update_or_destroy(
    update_or_destroy,
    klass,
    fields,
    parents
  )
    GraphQL::Relay::Mutation.define do
      mapping = instance_exec(&GraphqlCrudOperations.type_mapping)
      name "#{update_or_destroy.to_s.capitalize}#{klass.name.pluralize}"

      input_field :ids, !types[types.ID]
      fields.each do |field_name, field_type|
        input_field field_name, mapping[field_type]
      end

      return_field :ids, types[types.ID]
      if update_or_destroy.to_s == "update"
        return_field(:updated_objects, types["Types::#{klass.name}Type".constantize])
      end
      GraphqlCrudOperations
        .define_parent_returns(parents)
        .each do |field_name, field_class|
          return_field(field_name, field_class)
        end

      resolve ->(_root, inputs, ctx) {
                GraphqlCrudOperations.apply_bulk_update_or_destroy(
                  inputs,
                  ctx,
                  update_or_destroy,
                  klass
                )
              }
    end
  end

  def self.define_bulk_update(klass, fields, parents)
    self.define_bulk_update_or_destroy(:update, klass, fields, parents)
  end

  def self.define_bulk_destroy(klass, fields, parents)
    self.define_bulk_update_or_destroy(:destroy, klass, fields, parents)
  end

  def self.apply_bulk_update_or_destroy(inputs, ctx, update_or_destroy, klass)
    if inputs[:ids].size > 10_000
      raise I18n.t(:bulk_operation_limit_error, limit: 10_000)
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
    obj_ability = klass.new
    obj_ability.team = Team.current if obj_ability.respond_to?(:team=)
    if obj_ability.class.name == "Relationship"
      obj_ability.source = ProjectMedia.new(team: Team.current)
      obj_ability.target = ProjectMedia.new(team: Team.current)
    end
    if ability.can?("bulk_#{update_or_destroy}".to_sym, obj_ability)
      filtered_inputs =
        inputs
          .to_h
          .reject { |k, _v| %w[ids clientMutationId].include?(k.to_s) }
          .with_indifferent_access
      method_mapping = { update: :bulk_update, destroy: :bulk_destroy }
      method = method_mapping[update_or_destroy.to_sym]
      result = klass.send(method, sql_ids, filtered_inputs, Team.current)
      if update_or_destroy.to_s == "update"
        result.merge!({ updated_objects: klass.where(id: sql_ids) })
      end
      { ids: processed_ids }.merge(result)
    else
      raise CheckPermissions::AccessDenied, I18n.t(:permission_error)
    end
  end

  def self.define_bulk_create(klass, fields, parents)
    input_type = "Create#{klass.name.pluralize}BulkInput"
    definition =
      GraphQL::InputObjectType.define do
        mapping = instance_exec(&GraphqlCrudOperations.type_mapping)
        name(input_type)
        fields.each do |field_name, field_type|
          argument field_name, mapping[field_type]
        end
      end
    Object.const_set input_type, definition

    GraphQL::Relay::Mutation.define do
      name "Create#{klass.name.pluralize}"

      input_field :inputs, types[input_type.constantize]

      GraphqlCrudOperations
        .define_parent_returns(parents)
        .each do |field_name, field_class|
          return_field(field_name, field_class)
        end

      resolve ->(_root, input, ctx) {
                if input[:inputs].size > 10_000
                  raise I18n.t(:bulk_operation_limit_error, limit: 10_000)
                end

                ability = ctx[:ability] || Ability.new
                if ability.can?(:bulk_create, klass.new(team: Team.current))
                  klass.bulk_create(input["inputs"], Team.current)
                else
                  raise CheckPermissions::AccessDenied,
                        I18n.t(:permission_error)
                end
              }
    end
  end

  def self.define_destroy(type, parents = [])
    GraphQL::Relay::Mutation.define do
      name "Destroy#{type.camelize}"

      input_field :id, types.ID

      input_field(:keep_completed_tasks, types.Boolean) if type == "team_task"

      if type == "relationship"
        input_field(:add_to_project_id, types.Int)
        input_field(:archive_target, types.Int)
      end

      input_field(:items_destination_project_id, types.Int) if type == "project"

      return_field :deletedId, types.ID

      GraphqlCrudOperations
        .define_parent_returns(parents)
        .each do |field_name, field_class|
          return_field(field_name, field_class)
        end

      resolve ->(_root, inputs, ctx) {
                GraphqlCrudOperations.destroy(type, inputs, ctx, parents)
              }
    end
  end

  def self.define_parent_returns(parents = [])
    fields = {}
    parents.each do |parent|
      parentclass =
        (
          if parent =~ /^check_search_/
            "CheckSearch"
          else
            parent.gsub(/_was$/, "").camelize
          end
        )
      parentclass = "ProjectMedia" if %w[
        related_to
        source_project_media
        target_project_media
      ].include?(parent)
      parentclass = "TagText" if parent == "tag_text_object"
      parentclass = "Project" if parent == "previous_default_project"
      fields[parent.to_sym] = "Types::#{parentclass}Type".constantize
    end
    fields
  end

  def self.define_crud_operations(
    type,
    create_fields,
    update_fields = {},
    parents = []
  )
    update_fields = create_fields if update_fields.empty?
    [
      GraphqlCrudOperations.define_create_or_update("create", type, create_fields, parents),
      GraphqlCrudOperations.define_create_or_update("update", type, update_fields, parents),
      GraphqlCrudOperations.define_destroy(type, parents)
    ]
  end

  def self.define_annotation_mutation_fields
    { fragment: "str", annotated_id: "str", annotated_type: "str" }
  end

  def self.load_if_can(klass, id, ctx)
    klass.find_if_can(id, ctx[:ability])
  end
end
