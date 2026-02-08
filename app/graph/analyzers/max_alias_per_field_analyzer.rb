module Analyzers
  class MaxAliasPerFieldAnalyzer < GraphQL::Analysis::AST::Analyzer
    MAX_ALIASES_PER_FIELD = CheckConfig.get(:max_aliases_per_field, 10, :integer)

    def initialize(query)
      super
      @alias_count_by_field = Hash.new(0)
    end

    def on_enter_field(node, parent, visitor)
      if node.alias
        field_name = node.name
        @alias_count_by_field[field_name] += 1
      end
    end

    def result
      exceeded = @alias_count_by_field.find do |_field, count|
        count > MAX_ALIASES_PER_FIELD
      end
      return unless exceeded
      field, count = exceeded
      GraphQL::AnalysisError.new("Field '#{field}' can be queried with an alias at most #{MAX_ALIASES_PER_FIELD} times (got #{count}).")
    end
  end
end
