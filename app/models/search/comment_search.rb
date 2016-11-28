class CommentSearch

  include CheckElasticSearchModel

  #mapping _parent: { type: 'media_search' }
  attribute :text, String

end
