require 'check_graphql'

class RelayOnRailsSchema < GraphQL::Schema
  query QueryType
  mutation MutationType

  use GraphQL::Batch

  # Opt in to the new runtime (default in future graphql-ruby versions)
  # use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST

  lazy_resolve(Concurrent::Future, :value)

  class << self
    def resolve_type(_type, object, _ctx)
      klass = (object.respond_to?(:type) && object.type) ? object.type : object.class_name
      klass = 'Task' if Task.task_types.include?(klass)
      klass = 'User' if object.class.name == 'User'
      "#{klass}Type".constantize
    end

    def id_from_object(obj, type, ctx)
      CheckGraphql.id_from_object(obj, type, ctx)
    end

    def object_from_id(id, ctx)
      CheckGraphql.object_from_id(id, ctx)
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(err.message, options: { code: ::LapisConstants::ErrorCodes::ID_NOT_FOUND })
  end

  rescue_from CheckPermissions::AccessDenied do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(err.message, options: { code: ::LapisConstants::ErrorCodes::ID_NOT_FOUND })
  end
end
