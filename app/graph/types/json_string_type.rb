class JsonStringType < BaseScalar
  # Keep consistent with previous implementation
  graphql_name 'JsonStringType'

  def self.coerce_input(val, _ctx)
    begin JSON.parse(val) rescue val end
  end

  def self.coerce_result(val, _ctx)
    val.as_json
  end
end
