# This class is used to return data about a cluster under the scope of a team
# The idea is to simplify the logic on the GraphQL API layer
class ClusterTeam
  def initialize(cluster, team)
    @cluster = cluster
    @team = team
  end

  def id
    "#{@cluster.id}.#{@team.id}"
  end

  def team
    @team
  end

  def project_medias
    @cluster.project_medias.where(team_id: @team.id)
  end

  def last_request_date
    self.project_medias.map(&:last_seen).sort.last # FIXME: We don't expect thousands of items per team in a cluster, but if so, this can be a performance issue
  end

  def media_count
    self.project_medias.count
  end

  def requests_count
    self.project_medias.map(&:requests_count).sum
  end
end
