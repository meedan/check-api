class TagSearch
  include CheckElasticSearchModel

  attribute :tag, String, presence: true, mapping: { fields: { raw: { type: "string", index: "not_analyzed" } } }

  validates_presence_of :tag

  mapping _parent: { type: 'media_search' }

end
