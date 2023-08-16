class SnakeCaseField < GraphQL::Schema::Field
  def initialize(*args, **kwargs, &block)
    # Force GraphQL not to convert fields to camel case by default
    kwargs[:camelize] ||= false

    super(*args, **kwargs, &block)
  end
end
