module GraphQL
  module Relay
    class Edge
      def self.between(child_node, parent_node)
        relation = nil
        relation = Version.from_partition(parent_node.team_id).where(id: child_node.id) if child_node.is_a?(Version) && parent_node.class == ProjectMedia
        relation ||= child_node.is_annotation? ? parent_node.annotation_relation : parent_node.send(child_node.class_name.underscore.pluralize)
        relation = child_node.class.where(id: child_node.id) if self.not_part_of_relation(relation, child_node)
        parent_connection = GraphQL::Relay::RelationConnection.new(relation, {})
        self.new(child_node, parent_connection)
      end

      def self.not_part_of_relation(relation, child_node)
        relation.nil? || (relation.is_a?(Array) ? !relation.include?(child_node) : relation.where(id: child_node.id).count == 0)
      end
    end

    class PermissionedConnection < RelationConnection
      def sliced_nodes
        super
        @sliced_nodes = @sliced_nodes.permissioned
      end

      def edge_nodes
        @edge_nodes ||= paged_nodes
        @edge_nodes = @edge_nodes.map(&:load) if @field.name == 'annotations'
        @edge_nodes
      end
    end

    BaseConnection.register_connection_implementation(ActiveRecord::Relation, PermissionedConnection)
  end
end
