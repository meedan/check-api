class MediaSearch

  include CheckElasticSearchModel

  attribute :team_id, Integer
  attribute :project_id, Integer
  attribute :annotated_type, String, mapping: { type: 'text' }
  attribute :annotated_id, Integer
  attribute :associated_type, String, mapping: { type: 'keyword' }
  attribute :relationship_sources, Array, mapping: { type: 'text' }
  attribute :title, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :description, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :quote, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :accounts, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'integer'},
      username: { type: 'text', analyzer: 'check'},
      title: { type: 'text', analyzer: 'check'},
      description: { type: 'text', analyzer: 'check'}
    }
  }
  attribute :comments, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'text'},
      text: { type: 'text', analyzer: 'check'}
    }
  }
  attribute :tags, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'integer'},
      tag: { type: 'text', fields: { raw: { type: "keyword" } } }
    }
  }

  attribute :dynamics, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'integer'},
      datetime: { type: 'integer' },
      location: { type: 'geo_point' },
      indexable: { type: 'text', analyzer: 'check'}
    }
  }

  def set_es_annotated(obj)
    self.send("annotated_type=", obj.class.name)
    self.send("annotated_id=", obj.id)
  end
end
