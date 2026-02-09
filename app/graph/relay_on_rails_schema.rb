require 'check_graphql'

class RelayOnRailsSchema < GraphQL::Schema
  query QueryType
  mutation MutationType

  use GraphQL::Batch

  # These become default in graphql ruby 1.12+
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST
  use GraphQL::Execution::Errors

  query_analyzer Analyzers::MaxAliasPerFieldAnalyzer

  lazy_resolve(Concurrent::Future, :value)

  disable_introspection_entry_points unless Rails.env.development?

  class << self
    def resolve_type(_type, object, _ctx)
      klass = (object.respond_to?(:type) && object.type) ? object.type : object.class_name
      klass = 'Task' if Task.task_types.include?(klass)
      klass = 'User' if object.class.name == 'User'
      "#{klass}Type".constantize
    end

    def id_from_object(object, type, ctx)
      CheckGraphql.id_from_object(object, type, ctx)
    end

    def object_from_id(id, ctx)
      CheckGraphql.object_from_id(id, ctx)
    end
  end

  # Any types that are not explicitly declared as return types
  # somewhere in our schema. Otherwise our schema won't know about
  orphan_types(
    AccountSourceType,
    ProjectMediaUserType,
    RelationshipType,
    TiplineNewsletterType
  )

  rescue_from ActiveRecord::RecordNotFound do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(err.message, options: { code: ::LapisConstants::ErrorCodes::ID_NOT_FOUND })
  end

  rescue_from CheckPermissions::AccessDenied do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(err.message, options: { code: ::LapisConstants::ErrorCodes::ID_NOT_FOUND })
  end
end
