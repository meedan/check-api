module GraphQL
  module Relay
    class Edge < GraphQL::ObjectType
      def self.between(child_node, parent_node)
        parent_connection = GraphQL::Relay::RelationConnection.new(parent_node.annotation_relation, {})
        self.new(child_node, parent_connection)
      end
    end
  end
end
