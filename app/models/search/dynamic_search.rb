class DynamicSearch
  include CheckElasticSearchModel

  attribute :indexable, String, presence: true, mapping: { analyzer: 'hashtag' }
  validates_presence_of :indexable

  mapping _parent: { type: 'media_search' }
end
