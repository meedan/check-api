class CommentSearch
  include CheckElasticSearchModel

  attribute :text, String, presence: true, mapping: { analyzer: 'check' }
  validates_presence_of :text

  mapping _parent: { type: 'media_search' }
end
