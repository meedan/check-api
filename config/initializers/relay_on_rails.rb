require 'apollo/tracing'

RelayOnRailsSchema = GraphQL::Schema.define do
  query QueryType
  mutation MutationType
  use GraphQL::Batch
  use(ApolloTracing.new) if File.exist?(File.join(Rails.root, 'config', 'apollo-engine-proxy.json'))
  lazy_resolve(Concurrent::Future, :value)
  # Slow fields should be resolved this way:
  # field :slow_field, types.String do
  #   resolve -> (obj, _args, ctx) {
  #     team = Team.current
  #     user = User.current
  #     Concurrent::Future.execute(executor: POOL) {
  #       Team.current = team
  #       User.current = user
  #       <your code here>
  #     }
  #   }
  # end

  resolve_type -> (_type, object, _ctx) do
    klass = (object.respond_to?(:type) && object.type) ? object.type : object.class_name
    klass = 'Task' if Task.task_types.include?(klass)
    klass = 'User' if object.class.name == 'User'
    "#{klass}Type".constantize
  end

  id_from_object -> (obj, type, ctx) {
    CheckGraphql.id_from_object(obj, type, ctx)
  }

  object_from_id -> (id, ctx) do
    CheckGraphql.object_from_id(id, ctx)
  end
end

class CheckGraphql
  def self.id_from_object(obj, type, _ctx)
    return obj.id if obj.is_a?(CheckSearch)
    Base64.encode64("#{type}/#{obj.id}")
  end

  def self.decode_id(id)
    Base64.decode64(id).split('/')
  end

  def self.object_from_id(id, _ctx)
    type_name, id = CheckGraphql.decode_id(id)
    obj = nil
    if type_name == 'About'
      name = Rails.application.class.parent_name
      obj = OpenStruct.new({ name: name, version: VERSION, id: 1, type: 'About' })
    elsif ['Relationships', 'RelationshipsSource', 'RelationshipsTarget'].include?(type_name)
      obj = ProjectMedia.find(id)
    elsif type_name == 'CheckSearch'
      obj = CheckSearch.new(id)
    else
      obj = type_name.constantize.find_if_can(id)
    end
    obj
  end
end

POOL = Concurrent::ThreadPoolExecutor.new(
  min_threads: 1,
  max_threads: 5,
  max_queue: 0 # unbounded work queue
)
