class ProjectMediaCacheWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'cache', retry: 0

  PROJECT_MEDIA_CACHED_FIELDS = [
    'linked_items_count', 'suggestions_count', 'is_suggested', 'is_confirmed',
    'related_count', 'requests_count', 'demand', 'last_seen', 'description',
    'title', 'status', 'report_status', 'tags_as_sentence', 'sources_as_sentence',
    'media_published_at', 'published_by', 'type_of_media', 'added_as_similar_by_name',
    'confirmed_as_similar_by_name', 'show_warning_cover', 'picture',
    'team_name', 'creator_name'
  ]

  def perform(pmid)
    pm = ProjectMedia.find(pmid)
    PROJECT_MEDIA_CACHED_FIELDS.each { |field| pm.send(field) } # Just cache if it's not cached yet
  end
end
