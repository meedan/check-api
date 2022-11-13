class RelayOnRailsSchema < GraphQL::Schema
  query QueryType
  mutation MutationType
  use GraphQL::Batch
  lazy_resolve(Concurrent::Future, :value)

  def self.resolve_type(_type, object, _ctx)
    klass = (object.respond_to?(:type) && object.type) ? object.type : object.class_name
    klass = 'Task' if Task.task_types.include?(klass)
    klass = 'User' if object.class.name == 'User'
    "#{klass}Type".constantize
  end

  def self.id_from_object(obj, type, ctx)
    CheckGraphql.id_from_object(obj, type, ctx)
  end

  def self.object_from_id(id, ctx)
    CheckGraphql.object_from_id(id, ctx)
  end

  rescue_from ActiveRecord::RecordNotFound do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(err.message, options: { code: ::LapisConstants::ErrorCodes::ID_NOT_FOUND })
  end

  rescue_from CheckPermissions::AccessDenied do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(err.message, options: { code: ::LapisConstants::ErrorCodes::ID_NOT_FOUND })
  end

  # FOR TESTS ONLY:
  # This method is to help us regenerate the GraphQL schema when we make
  # database modifications to annotation types
  #
  # Only meant to be used when we make schema-impacting database modifications
  # in tests, otherwise should rely on default behavior for schema to more
  # closely match dev & deployed behavior
  #
  # Approach taken from:
  # https://github.com/rmosolgo/graphql-ruby/issues/2225
  def self.reload_mutations!(restart_coverage = false)
    raise "Reloadable schema only meant to be used in test environment" unless Rails.env.test?

    # Make sure that coverage results are preserved once mutations are reloaded
    # https://github.com/simplecov-ruby/simplecov/issues/389
    if restart_coverage
      require 'simplecov'
      SimpleCov.result
      SimpleCov.start do
        command_name "#{command_name}1"
      end
    end

    @graphql_definition = nil

    ::Object.send(:remove_const, :MutationType) if defined?(MutationType)
    load "#{Rails.root}/app/graphql/types/mutation_type.rb"

    # Reset graphql_definition
    mutation MutationType
  end
end

class CheckGraphql
  def self.id_from_object(obj, type, _ctx)
    return obj.id if obj.is_a?(CheckSearch)
    Base64.encode64("#{type}/#{obj.id}")
  end

  def self.decode_id(id)
    begin Base64.decode64(id).split('/') rescue [nil, nil] end
  end

  def self.object_from_id(id, ctx)
    type_name, id = CheckGraphql.decode_id(id)
    obj = nil
    return obj if type_name.blank?
    if type_name == 'About'
      name = Rails.application.class.parent_name
      obj = OpenStruct.new({ name: name, version: VERSION, id: 1, type: 'About' })
    elsif ['Relationships', 'RelationshipsSource', 'RelationshipsTarget'].include?(type_name)
      obj = ProjectMedia.find_if_can(id)
    elsif type_name == 'CheckSearch'
      Team.find_if_can(Team.current&.id.to_i, ctx[:ability])
      obj = CheckSearch.new(id)
    else
      obj = type_name.constantize.find_if_can(id)
    end
    if type_name == 'TeamUser' && obj.class_name != 'TeamUser'
      obj = obj.becomes(TeamUser)
      obj.type = nil
      obj.instance_variable_set(:@new_record, false)
    end
    obj
  end
end

POOL = Concurrent::ThreadPoolExecutor.new(
  min_threads: 1,
  max_threads: 20,
  max_queue: 0 # unbounded work queue
)
