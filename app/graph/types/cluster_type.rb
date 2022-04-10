ClusterType = GraphqlCrudOperations.define_default_type do
  name 'Cluster'
  description 'Cluster type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :size, types.Int
  field :team_names, types[types.String]
  field :fact_checked_by_team_names, JsonStringType
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
    resolve -> (cluster, _args, ctx) {
      Cluster.find_if_can(cluster.id, ctx[:ability])
      cluster.project_medias.joins(:team).where('teams.country' => Team.current.country)
    }
  end

  connection :claim_descriptions, -> { ClaimDescriptionType.connection_type } do
    resolve -> (cluster, _args, ctx) {
      Cluster.find_if_can(cluster.id, ctx[:ability])
      ClaimDescription.joins(project_media: :team).where('project_medias.cluster_id' => cluster.id, 'teams.country' => Team.current.country)
    }
  end
end
