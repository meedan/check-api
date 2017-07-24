class AccountSearch
  include CheckElasticSearchModel

  attribute :username, String, mapping: { analyzer: 'check' }
  attribute :title, String, mapping: { analyzer: 'check' }
  attribute :description, String, mapping: { analyzer: 'check' }

  mapping _parent: { type: 'media_search' }
end
