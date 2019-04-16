module GraphQL
  module Relay
    class Edge
      def self.between(child_node, parent_node)
        relation = nil
        relation = PaperTrail::Version.where(id: child_node.id) if child_node.is_a?(PaperTrail::Version) && parent_node.is_a?(ProjectMedia)
        relation ||= child_node.is_annotation? ? parent_node.annotation_relation : parent_node.send(child_node.class_name.underscore.pluralize)
        relation = child_node.class.where(id: child_node.id) if relation.where(id: child_node.id).count == 0
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
