class PermissionedConnection < GraphQL::Pagination::ActiveRecordRelationConnection
  def sliced_nodes
    super
    @sliced_nodes = @sliced_nodes.permissioned
  end

  def edge_nodes
    @edge_nodes ||= paged_nodes
    @edge_nodes = @edge_nodes.map(&:load) if @field.name == 'annotations'
    @edge_nodes
  end

  def total_count
    @nodes.limit(nil).reorder(nil).offset(nil).count
  end
end
