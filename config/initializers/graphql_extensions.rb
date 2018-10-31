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
        klass = nodes.class.to_s.gsub(/::ActiveRecord.*$/, '')
        all_params = RequestStore.store[:graphql_connection_params] || {}
        user = User.current || User.new
        params = all_params[user.id] ||= {}
        if params[klass]
          params = params[klass].clone
          joins = params.delete(:joins)
          @sliced_nodes = @sliced_nodes.joins(joins) if joins
          @sliced_nodes = @sliced_nodes.where(params) unless params.empty?
        end
        @sliced_nodes
      end
    end

    BaseConnection.register_connection_implementation(ActiveRecord::Relation, PermissionedConnection)
  end
end
