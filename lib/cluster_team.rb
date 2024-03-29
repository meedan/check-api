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

  def requests
    TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: self.project_medias.map(&:id)).where('created_at < ?', @cluster.created_at)
  end

  def last_request_date
    return nil if self.requests.count == 0
    self.requests.order('created_at DESC').first.created_at.to_i
  end

  def media_count
    self.project_medias.count
  end

  def requests_count
    self.requests.count
  end

  def fact_checks
    return [] unless @cluster.feed.data_points.to_a.include?(1) # Return empty if feed is not sharing fact-checks
    list = []
    ClaimDescription.where(project_media_id: self.project_medias.map(&:id)).each do |claim_description|
      item = claim_description.project_media
      fact_check = claim_description.fact_check if item.report_status == 'published'
      list << OpenStruct.new({
        id: claim_description.id,
        claim: claim_description.description,
        fact_check_title: fact_check&.title,
        fact_check_summary: fact_check&.summary,
        rating: item.status_i18n,
        media_count: item.linked_items_count,
        requests_count: item.demand,
        claim_description: claim_description
      })
    end
    list
  end
end
