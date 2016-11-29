class TagSearch
  include CheckElasticSearchModel

  attribute :tag, String, presence: true
  attribute :full_tag, String, presence: true, mapping: { index: 'not_analyzed' }

  validates_presence_of :tag

  #mapping _parent: { type: 'media_search' }

end
