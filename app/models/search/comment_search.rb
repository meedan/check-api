class CommentSearch

  include CheckElasticSearchModel

  mapping _parent: { type: 'media_search' }
  attribute :text, String, presence: true, mapping: { analyzer: 'hashtag' }
  validates_presence_of :text

end
