class Cluster < ApplicationRecord
  has_many :cluster_project_medias, dependent: :destroy
  has_many :project_medias, through: :cluster_project_medias

  belongs_to :feed
  belongs_to :project_media, optional: true # Center

  def center
    self.project_media || self.items.first
  end

  def items
    self.project_medias
  end

  def size
    self.project_medias.count
  end

  def import_media_to_team(team, from_project_media, claim_title = nil, claim_context = nil)
    ProjectMedia.create!({
      team: team,
      channel: { main: CheckChannels::ChannelCodes::SHARED_DATABASE },
      media_id: from_project_media.media_id,
      imported_from_feed_id: self.feed_id,
      imported_from_project_media_id: from_project_media.id,
      set_claim_description: claim_title,
      set_claim_context: claim_context
    })
  end

  def import_medias_to_team(team, claim_title, claim_context, parent_id = nil)
    # Find the first item in this cluster for which the media_id doesn't exist in the target team yet
    # Should be fine to load these in memory since clusters don't contain thousands of media
    existing_items = self.project_medias.where(team_id: team.id).to_a
    from_project_media = self.project_medias.where.not(team_id: team.id).select(:id, :media_id).find do |item|
      existing_item = ProjectMedia.where(team_id: team.id, media_id: item.media_id).first
      existing_items << existing_item
      existing_item.nil?
    end
    raise ActiveRecord::RecordNotUnique.new(I18n.t(:shared_feed_imported_media_already_exist, urls: existing_items.map(&:full_url).uniq.compact_blank.join(', '))) if from_project_media.nil?
    parent = nil
    if parent_id.nil?
      parent = self.import_media_to_team(team, from_project_media, claim_title, claim_context)
    else
      parent = ProjectMedia.where(id: parent_id, team_id: team.id).last
    end
    self.class.import_other_medias_to_team(self.id, parent.id, CheckConfig.get('shared_feed_min_media_to_bulk_import', 5, :integer)) # If there are just a few items, we don't even need to wait for the background job
    self.class.delay_for(1.second).import_other_medias_to_team(self.id, parent.id, CheckConfig.get('shared_feed_max_media_to_bulk_import', 100, :integer))
    parent
  end

  def self.import_other_medias_to_team(cluster_id, parent_id, max)
    cluster = Cluster.find_by_id(cluster_id)
    parent = ProjectMedia.find_by_id(parent_id)
    return if cluster.nil? || parent.nil?
    team = parent.team
    cluster.project_medias.where.not(team_id: team.id).limit(max).select(:id, :media_id).find_each do |pm|
      next if ProjectMedia.where(team_id: team.id, media_id: pm.media_id).exists?
      target = cluster.import_media_to_team(team, pm)
      Relationship.create(source: parent, target: target, relationship_type: Relationship.confirmed_type) # Didn't use "!" so if fails silently if the similarity bot creates a relationship first
    end
  end
end
