module GraphQL
  module Relay
    class Edge
      def self.between(child_node, parent_node)
        relation = child_node.is_annotation? ? parent_node.annotation_relation : parent_node.send(child_node.class_name.underscore.pluralize)
        parent_connection = GraphQL::Relay::RelationConnection.new(relation, {})
        self.new(child_node, parent_connection)
      end
    end
  end
end
