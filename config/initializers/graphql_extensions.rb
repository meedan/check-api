module GraphQL::Relay
  class Edge
    class << self
      def between(child_node, parent_node)
        relation = nil
        relation = Version.from_partition(parent_node.team_id).where(id: child_node.id) if child_node.is_a?(Version)
        relation ||= child_node.is_annotation? ? parent_node.annotation_relation : parent_node.send(child_node.class_name.underscore.pluralize)
        relation = child_node.class.where(id: child_node.id) if self.not_part_of_relation(relation, child_node)
        parent_connection = GraphQL::Pagination::ActiveRecordRelationConnection.new(relation, {})
        self.new(child_node, parent_connection)
      end

      def not_part_of_relation(relation, child_node)
        relation.nil? || (relation.is_a?(Array) ? !relation.include?(child_node) : relation.where(id: child_node.id).count == 0)
      end
    end
  end
end
