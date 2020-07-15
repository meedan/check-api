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
    attrs.each do |key, value|
      method = key == 'clientMutationId' ? 'client_mutation_id=' : "#{key}="
      obj.send(method, value) if obj.respond_to?(method)
    end
    obj.disable_es_callbacks = Rails.env.to_s == 'test'
    obj.save!

    name = obj.class_name.underscore
    { name.to_sym => obj }.merge(GraphqlCrudOperations.define_returns(obj, inputs, parents))
  end

  def self.define_returns(obj, inputs, parents)
    ret = {}
    name = obj.class_name.underscore
    parents.each do |parent_name|
      child, parent = obj, obj.send(parent_name)
      unless parent.nil?
        parent.no_cache = true if parent.respond_to?(:no_cache)
        parent = self.define_optimistic_fields(parent, inputs, parent_name)
        ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(child, parent) if !['related_to', 'public_team', 'first_response_version', 'comment_version', 'source_project_media', 'target_project_media', 'current_project_media'].include?(parent_name) && !child.is_a?(ProjectMediaProject)
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

    if [Comment, Task].include?(obj.class)
      mapping = { 'Task' => 'first_response_version', 'Comment' => 'comment_version' }
      method = mapping[obj.class_name]
      version = obj.send(method)
      ret["#{method}Edge".to_sym] = GraphQL::Relay::Edge.between(version, obj.annotated) unless version.nil?
    end

    ret = ret.merge(GraphqlCrudOperations.get_affected_ids(obj))

    ret
  end

  def self.get_affected_ids(obj)
    ret = {}
    ret[:affectedIds] = obj.affected_ids if obj.respond_to?(:affected_ids)
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

  def self.bulk_create(type, inputs)
    self.delay_for(1.second, retry: false).bulk_create_in_background(type, inputs.map(&:to_h).to_json, User.current&.id, Team.current&.id)
    { enqueued: true }
  end

  def self.bulk_create_in_background(type, json_inputs, user_id, team_id)
    User.current = User.find(user_id)
    Team.current = Team.find(team_id)
    klass = type.camelize.constantize
    inputs = JSON.parse(json_inputs)
    inputs.each do |input|
      obj = klass.new
      obj.is_being_created = true if obj.respond_to?(:is_being_created)
      input.each do |key, value|
        obj.send("#{key}=", value)
      end
      obj.save!
    end
    User.current = nil
    Team.current = nil
  end

  def self.target_pusher_channels(obj, operation)
    obj.bulk_channels(operation.to_sym)
  end

  def self.send_bulk_pusher_notification(event, channels = [])
    return if CONFIG['pusher_key'].blank?
    ::Pusher.trigger([User.current.pusher_channel], event, { message: { pusherChannels: [], pusherEvent: 'bulk' }.to_json }) if User.current
    ::Pusher.trigger(['check-api-global-channel'], 'update', { message: { pusherChannels: channels, pusherEvent: event }.to_json }) unless channels.empty?
  end

  def self.operation_from_multiple_ids(operation, ids, inputs, channels, uid, tid)
    User.current = User.where(id: uid).last
    Team.current = Team.where(id: tid).last
    ids_list = ids.split(',')
    attrs = JSON.parse(inputs)
    attrs[:skip_notifications] = true
    attrs['clientMutationId'] = nil
    ids_list.each do |id|
      begin
        self.send_bulk_pusher_notification("bulk_#{operation}_update", channels)
        self.send("#{operation}_from_single_id", id, attrs, {}, [])
      rescue
        Rails.logger.info "Bulk-action #{operation} failed for id #{id}"
      end
    end
    self.freeze_or_unfreeze_objects(ids_list, false)
    self.send_bulk_pusher_notification("bulk_#{operation}_end", channels)
    User.current = Team.current = nil
  end

  def self.freeze_or_unfreeze_objects(graphql_ids, inactive)
    objs = {}
    graphql_ids.each do |graphql_id|
      klass, id = CheckGraphql.decode_id(graphql_id)
      objs[klass.constantize] ||= []
      objs[klass.constantize] << id
    end
    objs.each { |klass, ids| klass.where(id: ids).update_all(inactive: inactive) if klass.column_names.include?('inactive') }
  end

  def self.crud_operation(operation, obj, inputs, ctx, parents, returns = {})
    if inputs[:ids]
      params = {}
      inputs.keys.each{ |k| params[k] = inputs[k] }
      ret = { affectedIds: inputs[:ids] }.merge(returns)
      self.freeze_or_unfreeze_objects(inputs[:ids], true) unless inputs[:no_freeze]
      channels = self.target_pusher_channels(obj, operation)
      self.send_bulk_pusher_notification("bulk_#{operation}_start", channels)
      self.delay_for(1.second, retry: false).operation_from_multiple_ids(operation, inputs[:ids].join(','), params.to_json, channels, User.current&.id, Team.current&.id)
      ret
    elsif inputs[:id] || obj
      self.send("#{operation}_from_single_id", inputs[:id] || obj.graphql_id, inputs, ctx, parents)
    end
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

  def self.prepopulate_object(obj, inputs)
    inputs.each do |key, value|
      obj.send("#{key}=", value) if obj.respond_to?("#{key}=")
    end
    obj
  end

  def self.update(_type, inputs, ctx, parents = [])
    obj = inputs[:id] ? self.object_from_id_and_context(inputs[:id], ctx) : nil
    obj = self.prepopulate_object(obj, inputs) if inputs[:ids]
    returns = (obj.nil? || !inputs[:ids]) ? {} : GraphqlCrudOperations.define_returns(obj, inputs, parents)
    self.crud_operation('update', obj, inputs, ctx, parents, returns)
  end

  def self.destroy_from_single_id(graphql_id, inputs, ctx, parents)
    obj = self.object_from_id(graphql_id)
    obj.current_id = inputs[:current_id] if obj.is_a?(Relationship)
    obj.keep_completed_tasks = inputs[:keep_completed_tasks] if obj.is_a?(TeamTask)
    obj.disable_es_callbacks = (Rails.env.to_s == 'test') if obj.respond_to?(:disable_es_callbacks)
    obj.respond_to?(:destroy_later) ? obj.destroy_later(ctx[:ability]) : ActiveRecord::Base.connection_pool.with_connection { obj.destroy }

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

  def self.define_optimistic_fields(obj, inputs, name)
    if inputs[:ids]
      if name =~ /^check_search/
        obj = self.define_optimistic_fields_for_check_search(obj, inputs, name)
      end

      if name =~ /^project/
        obj = self.define_optimistic_fields_for_project(obj, inputs, name)
      end

      if name == 'team'
        obj = self.define_optimistic_fields_for_team(obj, inputs, name)
      end
    end

    if name == 'project_media'
      obj = self.define_optimistic_fields_for_project_media(obj, inputs, name)
    end

    if inputs['empty_trash']
      obj.define_singleton_method(:number_of_results) { 0 }
      if obj.is_a?(Team)
        public_team = obj.public_team
        public_team.define_singleton_method(:trash_count) { 0 }
        obj.define_singleton_method(:public_team) { public_team }
      end
    end

    obj
  end

  def self.define_optimistic_fields_for_project(obj, inputs, name)
    obj = Project.where(id: inputs['add_to_project_id']).last if name == 'project' && inputs['add_to_project_id']
    return nil if obj.nil?
    n = obj.medias_count
    obj.define_singleton_method(:medias_count) { n - inputs[:ids].size } if name == 'project_was'
    obj.define_singleton_method(:medias_count) { n + inputs[:ids].size } if name == 'project'
    obj
  end

  def self.define_optimistic_fields_for_team(obj, inputs, _name)
    obj = Team.current
    medias_count = obj.medias_count
    trash_count = obj.trash_count
    ids_count = inputs[:ids].size
    if inputs['archived'] == 1
      obj.define_singleton_method(:medias_count) { medias_count - ids_count }
      obj.define_singleton_method(:trash_count) { trash_count + ids_count }
    elsif inputs['archived'] == 0
      obj.define_singleton_method(:medias_count) { medias_count + ids_count }
      obj.define_singleton_method(:trash_count) { trash_count - ids_count }
    end
    obj
  end

  def self.define_optimistic_fields_for_check_search(obj, inputs, name)
    obj = Project.where(id: inputs['add_to_project_id']).last&.check_search_project if name == 'check_search_project' && inputs['add_to_project_id']
    return nil if obj.nil?
    n = obj.number_of_results
    obj.define_singleton_method(:number_of_results) { n - inputs[:ids].size } if name == 'check_search_project_was'
    if name == 'check_search_project'
      medias = ProjectMedia.where(id: inputs[:ids].collect{ |id| Base64.decode64(id).split('/').last.to_i }).to_a.reverse + obj.medias.first(20).to_a
      obj.define_singleton_method(:number_of_results) { n + inputs[:ids].size }
      obj.define_singleton_method(:medias) { medias }
    end
    obj
  end

  def self.define_optimistic_fields_for_project_media(obj, inputs, _name)
    status = begin JSON.parse(inputs[:set_fields])['verification_status_status'] rescue nil end
    unless status.nil?
      return obj if TeamBotInstallation.where(team_id: obj.team_id, user_id: BotUser.where(login: 'smooch').last&.id.to_i).last.nil?
      targets = []
      obj.targets_by_users.find_each do |target|
        target.define_singleton_method(:last_status) { status }
        target.define_singleton_method(:dbid) { 0 }
        targets << target
      end
      obj.define_singleton_method(:targets_by_users) { targets }
    end
    obj
  end

  def self.destroy(inputs, ctx, parents = [])
    returns = {}
    obj = nil
    obj = self.object_from_id(inputs[:id]) if inputs[:id]
    unless obj.nil?
      parents.each do |parent|
        parent_obj = obj.send(parent)
        parent_obj = self.define_optimistic_fields(parent_obj, inputs, parent)
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
        input_field :ids, types[types.ID]
      end
      input_field :no_freeze, types.Boolean
      fields.each { |field_name, field_type| input_field field_name, mapping[field_type] }

      klass = "#{type.camelize}Type".constantize
      return_field type.to_sym, klass

      return_field(:affectedIds, types[types.ID])
      return_field(:affectedId, types.ID) if type.to_s == 'project_media'

      if type.to_s == 'team'
        return_field(:team_userEdge, TeamUserType.edge_type)
        return_field(:user, UserType)
      end

      if type =~ /^dynamic_annotation_/
        return_field :dynamic, DynamicType
        return_field :dynamicEdge, DynamicType.edge_type
      end

      version_edge_name = { 'task' => 'first_response', 'comment' => 'comment' }[type.to_s]
      return_field("#{version_edge_name}_versionEdge".to_sym, VersionType.edge_type) if ['task', 'comment'].include?(type.to_s)

      return_field type.to_sym, klass
      return_field "#{type}Edge".to_sym, klass.edge_type
      GraphqlCrudOperations.define_parent_returns(parents).each{ |field_name, field_class| return_field(field_name, field_class) }

      resolve -> (_root, inputs, ctx) { GraphqlCrudOperations.send(action, type, inputs, ctx, parents) }
    end
  end

  def self.define_destroy(type, parents = [])
    GraphQL::Relay::Mutation.define do
      name "Destroy#{type.camelize}"

      input_field :id, types.ID
      input_field :ids, types[types.ID]

      if type == 'project_media_project'
        input_field :project_id, types.Int
        input_field :project_media_id, types.Int
      end

      input_field(:current_id, types.Int) if type == 'relationship'

      input_field(:keep_completed_tasks, types.Boolean) if type == 'team_task'

      return_field :deletedId, types.ID
      return_field :affectedIds, types[types.ID]

      GraphqlCrudOperations.define_parent_returns(parents).each{ |field_name, field_class| return_field(field_name, field_class) }

      resolve -> (_root, inputs, ctx) { GraphqlCrudOperations.destroy(inputs, ctx, parents) }
    end
  end

  def self.define_parent_returns(parents = [])
    fields = {}
    parents.each do |parent|
      parentclass = parent =~ /^check_search_/ ? 'CheckSearch' : parent.gsub(/_was$/, '').camelize
      parentclass = 'ProjectMedia' if ['related_to', 'source_project_media', 'target_project_media', 'current_project_media'].include?(parent)
      parentclass = 'Version' if ['first_response_version', 'comment_version'].include?(parent)
      parentclass = 'TagText' if parent == 'tag_text_object'
      fields[parent.to_sym] = "#{parentclass}Type".constantize
    end
    fields
  end

  def self.define_bulk_create(type, fields)
    input_type = "Create#{type.camelize.pluralize}Input"
    definition = GraphQL::InputObjectType.define do
      mapping = instance_exec(&GraphqlCrudOperations.type_mapping)
      name(input_type)
      fields.each { |field_name, field_type| argument field_name, mapping[field_type] }
    end
    Object.const_set input_type, definition

    GraphQL::Relay::Mutation.define do
      name "Create#{type.camelize.pluralize}Mutation"
      input_field :inputs, types[input_type.constantize]
      return_field :enqueued, types.Boolean
      resolve -> (_root, input, _ctx) { GraphqlCrudOperations.bulk_create(type, input['inputs']) }
    end
  end

  def self.define_crud_operations(type, create_fields, update_fields = {}, parents = [], generate_bulk_mutation = false)
    update_fields = create_fields if update_fields.empty?
    generated = [GraphqlCrudOperations.define_create(type, create_fields, parents), GraphqlCrudOperations.define_update(type, update_fields, parents), GraphqlCrudOperations.define_destroy(type, parents)]
    # FIXME: Do the same for update and destroy by refactoring them (#7858)
    # Should we create the bulk mutations for all types by default? For now, only if the parameter is true (to avoid a big schema)
    generated << GraphqlCrudOperations.define_bulk_create(type, create_fields) if generate_bulk_mutation
    generated
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

      field :image_data, JsonStringType

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
