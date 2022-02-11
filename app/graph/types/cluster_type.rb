ClusterType = GraphqlCrudOperations.define_default_type do
  name 'Cluster'
  description 'Cluster type'

  interfaces [NodeIdentification.interface]

  field :size, types.Int
  field :team_names, types[types.String]
  field :fact_checked_by_team_names, types[types.String]
  field :requests_count, types.Int

  field :first_item_at, types.Int do
    resolve -> (cluster, _args, _ctx) {
      cluster.first_item_at.to_i
    }
  end

  field :last_item_at, types.Int do
    resolve -> (cluster, _args, _ctx) {
      cluster.last_item_at.to_i
    }
  end

  connection :items, -> { ProjectMediaType.connection_type } do
    resolve -> (cluster, _args, _ctx) {
      User.current&.is_admin ? cluster.project_medias : []
    }
  end

  connection :claim_descriptions, -> { ClaimDescriptionType.connection_type } do
    resolve -> (cluster, _args, _ctx) {
      User.current&.is_admin ? cluster.claim_descriptions : []
    }
  end
end
