class GraphqlCrudOperations
  # Uses obj
  # Doesn't use inputs or parents, just passes through
  def self.safe_save(obj, attrs, parents = [])
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
      GraphqlCrudOperations.define_returns(obj, parents)
    )
  end

  def self.define_returns(obj, parents)
    ret = {}
    name = obj.class_name.underscore
    parents.each do |parent_name|
      parent_name = parent_name.keys.first if parent_name.is_a?(Hash)
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

  def self.update_from_single_id(id, inputs, ctx, parents)
    obj = self.object_from_id_and_context(id, ctx)
    obj.file = ctx[:file] if !ctx[:file].blank?

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key.to_sym == :id
      memo
    end

    self.safe_save(obj, attrs, parents)
  end

  def self.object_from_id_and_context(id, ctx)
    obj = CheckGraphql.object_from_id(id, ctx)
    obj = obj.load if obj.is_a?(Annotation)
    obj
  end

  def self.update(inputs, ctx, parents = [])
    obj = self.object_from_id_and_context(inputs[:id], ctx)
    return unless inputs[:id] || obj

    self.update_from_single_id(inputs[:id] || obj.graphql_id, inputs, ctx, parents)
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

  # Can delete _type
  def self.destroy(inputs, ctx, parents = [])
    obj = self.object_from_id(inputs[:id])
    self.destroy_from_single_id(obj, inputs, ctx, parents)
  end

  def self.destroy_from_single_id(obj, inputs, ctx, parents)
    raise "This operation must be done by a signed-in user" if User.current.nil?
    obj.keep_completed_tasks = inputs[:keep_completed_tasks] if obj.is_a?(TeamTask)
    if obj.is_a?(Relationship)
      obj.add_to_project_id = inputs[:add_to_project_id]
      obj.archive_target = inputs[:archive_target]
    end
    obj.items_destination_project_id = inputs[:items_destination_project_id] if obj.is_a?(Project)
    obj.disable_es_callbacks = (Rails.env.to_s == 'test') if obj.respond_to?(:disable_es_callbacks)
    obj.respond_to?(:destroy_later) ? obj.destroy_later(ctx[:ability]) : ApplicationRecord.connection_pool.with_connection { obj&.destroy }

    deleted_id = obj.respond_to?(:graphql_deleted_id) ? obj.graphql_deleted_id : graphql_id
    ret = { deletedId: deleted_id }

    parents.each { |parent| ret[parent.to_sym] = obj.send(parent) } unless obj.nil?

    ret
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

  def self.load_if_can(klass, id, ctx)
    klass.find_if_can(id, ctx[:ability])
  end
end
