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

  def fact_checks
    return [] unless @cluster.feed.data_points.to_a.include?(1) # Return empty if feed is not sharing fact-checks
    list = []
    ClaimDescription.where(project_media_id: self.project_medias.map(&:id)).each do |claim_description|
      item = claim_description.project_media
      list << OpenStruct.new({
        id: claim_description.id,
        claim: claim_description.description,
        fact_check_title: claim_description.fact_check&.title,
        fact_check_summary: claim_description.fact_check&.summary,
        rating: item.status_i18n,
        media_count: item.linked_items_count,
        requests_count: item.demand,
        claim_description: claim_description
      })
    end
    list
  end
end
