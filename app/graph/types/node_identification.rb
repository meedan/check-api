GraphQL::Relay::GlobalNodeIdentification.instance_variable_set(:@instance, nil)
NodeIdentification = 
  GraphQL::Relay::GlobalNodeIdentification.define do
  
  object_from_id -> (id, ctx) do
    type_name, id = NodeIdentification.from_global_id(id)
    type_name == 'About' ? OpenStruct.new({ name: Rails.application.class.parent_name, version: VERSION, id: 1, type: 'About' }) : type_name.find(id)
  end
  
  type_from_object -> (object) do
    klass = object.respond_to?(:type) ? object.type : object.class.name
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
