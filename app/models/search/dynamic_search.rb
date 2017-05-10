class DynamicSearch
  include CheckElasticSearchModel

  attribute :indexable, String, presence: true, mapping: { analyzer: 'check' }
  validates_presence_of :indexable

  mapping _parent: { type: 'media_search' }
end
