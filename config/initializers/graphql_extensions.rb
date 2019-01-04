module GraphQL
  module Relay
    class Edge
      def self.between(child_node, parent_node)
        relation = child_node.is_annotation? ? parent_node.annotation_relation : parent_node.send(child_node.class_name.underscore.pluralize)
        relation = child_node.class.where(id: child_node.id) unless relation.to_a.include?(child_node)
        parent_connection = GraphQL::Relay::RelationConnection.new(relation, {})
        self.new(child_node, parent_connection)
      end
    end

    class PermissionedConnection < RelationConnection
      def sliced_nodes
        super
        @sliced_nodes = @sliced_nodes.permissioned
      end
    end

    BaseConnection.register_connection_implementation(ActiveRecord::Relation, PermissionedConnection)
  end
end
