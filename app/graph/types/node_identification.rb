GraphQL::Relay::GlobalNodeIdentification.instance_variable_set(:@instance, nil)
NodeIdentification = GraphQL::Relay::GlobalNodeIdentification.define do
  object_from_id -> (id, ctx) do
    type_name, id = NodeIdentification.from_global_id(id)
    obj = nil
    if type_name == 'About'
      name = Rails.application.class.parent_name
      obj = OpenStruct.new({ name: name, version: VERSION, id: 1, type: 'About' })
    elsif type_name == 'CheckSearch'
      obj = CheckSearch.new(id)
    else
      obj = type_name.constantize.find_if_can(id)
      obj.origin = ctx[:origin] if obj.respond_to?('origin=')
      obj.project_id ||= ctx[:context_project].id if obj.respond_to?('project_id=') && ctx[:context_project].present?
    end
    obj
  end

  type_from_object -> (object) do
    klass = object.respond_to?(:type) ? object.type : object.class_name
    "#{klass}Type".constantize
  end

  to_global_id -> (type_name, id) do
    Base64.encode64("#{type_name}/#{id}")
  end

  from_global_id -> (global_id) do
    id_parts  = Base64.decode64(global_id).split("/")
    type_name = id_parts[0]
    id        = id_parts[1]
    [type_name, id]
  end
end
