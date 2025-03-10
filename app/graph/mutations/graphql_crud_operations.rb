class GraphqlCrudOperations
  def self.safe_save(obj, attrs, parent_names = [])
    raise "Can't save a null object." if obj.nil?
    raise 'This operation must be done by a signed-in user' if User.current.nil? && ApiKey.current.nil?
    attrs.each do |key, value|
      method = key == "clientMutationId" ? "client_mutation_id=" : "#{key}="
      obj.send(method, value) if obj.respond_to?(method)
    end
    obj.disable_es_callbacks = Rails.env.to_s == "test"

    begin
      obj.save_with_version!
    rescue RuntimeError => e
      if e.message.include?("\"code\":#{LapisConstants::ErrorCodes::const_get('DUPLICATED')}") &&
      obj.is_a?(ProjectMedia) &&
      obj.set_fact_check.present? &&
      obj.set_original_claim.present?
        existing_pm = ProjectMedia.find(JSON.parse(e.message)['data']['id'])
        obj = ProjectMedia.handle_fact_check_for_existing_claim(existing_pm,obj)
      else
        raise e
      end
    end

    name = obj.class_name.underscore
    { name.to_sym => obj }.merge(
      GraphqlCrudOperations.define_returns(obj, parent_names)
    )
  end

  # Parents is an array that can contain strings or a hash,
  # e.g. ['project_media', { project_media_was: ProjectMediaType }]
  #
  # This function standardizes name => types to an explicit type mapping and
  # returns the resulting hash, e.g. { project_media: ProjectMediaType, project_media_was: ProjectMediaType }
  def self.hashify_parent_types(parents)
    {}.with_indifferent_access.tap do |parent_type_mapping|
      parents.each do |parent|
        if parent.is_a?(Hash)
          parent_type_mapping.merge!(parent)
        else
          parent_type_mapping[parent.to_sym] = "#{parent.camelize}Type".constantize
        end
      end
    end
  end

  def self.define_returns(obj, parent_names)
    ret = {}
    obj_name = obj.class_name.underscore
    parent_names.each do |parent_name|
      child, parent = obj, obj.send(parent_name)
      parent = obj.version_object if parent_name == "version"
      unless parent.nil?
        parent.no_cache = true if parent.respond_to?(:no_cache)
        ret["#{obj_name}Edge".to_sym] = GraphQL::Relay::Edge.between(
          child,
          parent
        ) if !%w[related_to public_team version me].include?(parent_name)
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

    if [Task, Dynamic].include?(obj.class)
      version = obj.version_object
      ret["versionEdge".to_sym] = GraphQL::Relay::Edge.between(
        version,
        obj.annotated
      ) unless version.nil?
    end

    ret[:affected_id] = obj.graphql_id if obj.is_a?(ProjectMedia)

    ret
  end

  def self.create(type, inputs, ctx, parents_mapping = {})
    klass = type.camelize

    obj = klass.constantize.new
    obj.is_being_created = true if obj.respond_to?(:is_being_created)
    obj.file = ctx[:file] unless ctx[:file].blank?

    attrs =
      inputs
        .keys
        .inject({}) do |memo, key|
          memo[key] = inputs[key]
          memo
        end
    attrs["annotation_type"] = type.gsub(/^dynamic_annotation_/, "") if type =~
      /^dynamic_annotation_/

    self.safe_save(obj, attrs, parents_mapping.keys)
  end

  def self.update_from_single_id(_graphql_id, obj, inputs, ctx, parent_names)
    obj.file = ctx[:file] unless ctx[:file].blank?

    attrs = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key.to_sym == :id
      memo
    end

    self.safe_save(obj, attrs, parent_names)
  end

  def self.object_from_id_and_context(id, ctx)
    obj = CheckGraphql.object_from_id(id, ctx)
    obj = obj.load if obj.is_a?(Annotation)
    obj
  end

  def self.update(inputs, ctx, parents_mapping = {})
    obj = self.object_from_id_and_context(inputs[:id], ctx)
    return unless inputs[:id] || obj

    self.update_from_single_id(inputs[:id] || obj.graphql_id, obj, inputs, ctx, parents_mapping.keys)
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

  def self.destroy(inputs, ctx, parents_mapping = {})
    obj = self.object_from_id(inputs[:id])
    return unless inputs[:id] || obj

    self.destroy_from_single_id(inputs[:id] || obj.graphql_id, obj, inputs, ctx, parents_mapping.keys)
  end

  def self.destroy_from_single_id(graphql_id, obj, inputs, ctx, parent_names)
    raise "This operation must be done by a signed-in user" if User.current.nil?

    obj.keep_completed_tasks = inputs[:keep_completed_tasks] if obj.is_a?(TeamTask)
    if obj.is_a?(Relationship)
      obj.archive_target = inputs[:archive_target]
    end
    obj.items_destination_project_id = inputs[:items_destination_project_id] if obj.is_a?(Project)
    obj.disable_es_callbacks = (Rails.env.to_s == 'test') if obj.respond_to?(:disable_es_callbacks)
    obj.respond_to?(:destroy_later) ? obj.destroy_later(ctx[:ability]) : ApplicationRecord.connection_pool.with_connection { obj&.destroy }

    deleted_id = obj.respond_to?(:graphql_deleted_id) ? obj.graphql_deleted_id : graphql_id
    ret = { deleted_id: deleted_id }

    parent_names.each { |parent_name| ret[parent_name.to_sym] = obj.send(parent_name) } unless obj.nil?

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
      method_mapping = { update: :bulk_update, destroy: :bulk_destroy, mark_read: :bulk_mark_read }
      method = method_mapping[update_or_destroy.to_sym]
      result = klass.send(method, sql_ids, filtered_inputs, Team.current)
      if update_or_destroy.to_s != "destroy"
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
