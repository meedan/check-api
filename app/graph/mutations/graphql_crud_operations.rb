class GraphqlCrudOperations
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
        ret["#{name}Edge".to_sym] = GraphQL::Relay::Edge.between(child, parent) unless ['related_to', 'public_team', 'first_response_version', 'source_project_media', 'target_project_media', 'current_project_media'].include?(parent_name)
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

    if obj.is_a?(Task)
      version = obj.first_response_version
      ret["first_response_versionEdge".to_sym] = GraphQL::Relay::Edge.between(version, obj.annotated) unless version.nil?
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
      self.freeze_or_unfreeze_objects(inputs[:ids], true)
      channels = self.target_pusher_channels(obj, operation)
      self.send_bulk_pusher_notification("bulk_#{operation}_start", channels)
      self.delay_for(1.second, retry: false).operation_from_multiple_ids(operation, inputs[:ids].join(','), params.to_json, channels, User.current&.id, Team.current&.id)
      ret
    elsif inputs[:id]
      self.send("#{operation}_from_single_id", inputs[:id], inputs, ctx, parents)
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
    if inputs[:ids] && name =~ /^check_search/
      obj = self.define_optimistic_fields_for_check_search(obj, inputs, name)
    end
    
    if name == 'project_media'
      obj = self.define_optimistic_fields_for_project_media(obj, inputs, name)
    end
     
    obj.define_singleton_method(:number_of_results) { 0 } if inputs['empty_trash']

    obj
  end

  def self.define_optimistic_fields_for_check_search(obj, inputs, name)
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
      return obj if TeamBotInstallation.where(team_id: obj.project.team_id, team_bot_id: TeamBot.where(identifier: 'smooch').last&.id.to_i).last.nil?
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
    if inputs[:id]
      obj = self.object_from_id(inputs[:id])
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
      mapping = { 'str' => types.String, '!str' => !types.String, 'int' => types.Int, '!int' => !types.Int, 'id' => types.ID, '!id' => !types.ID, 'bool' => types.Boolean, 'json' => JsonStringType }

      name "#{action.camelize}#{type.camelize}"

      input_field :id, types.ID
      input_field :ids, types[types.ID]
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

      return_field(:first_response_versionEdge, VersionType.edge_type) if type.to_s == 'task'

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

      input_field(:current_id, types.Int) if type == 'relationship'

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
      parentclass = 'Version' if parent == 'first_response_version'
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
      connection :annotations, -> { AnnotationType.connection_type } do
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
        resolve ->(obj, _args, _ctx) {
          obj.get_versions_log
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

      field :locked, types.Boolean

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
