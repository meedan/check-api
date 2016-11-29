class CommentSearch

  include CheckElasticSearchModel

  attribute :text, String, presence: true, mapping: { analyzer: 'hashtag' }
  validates_presence_of :text

  mapping _parent: { type: 'media_search' }

end
