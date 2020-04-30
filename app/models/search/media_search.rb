class MediaSearch

  include CheckElasticSearchModel

  attribute :team_id, Integer
  attribute :project_id, Array, mapping: { type: 'integer' }
  attribute :annotated_type, String, mapping: { type: 'text' }
  attribute :annotated_id, Integer
  attribute :associated_type, String, mapping: { type: 'keyword' }
  attribute :relationship_sources, Array, mapping: { type: 'text' }
  attribute :title, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :description, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :quote, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :inactive, Integer
  attribute :archived, Integer
  attribute :sources_count, Integer
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
      tag: { type: 'text', analyzer: 'check', fields: { raw: { type: 'text' } } }
    }
  }
  attribute :dynamics, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'integer'},
      datetime: { type: 'integer' },
      location: { type: 'geo_point' },
      indexable: { type: 'text', analyzer: 'check'},
      language: { type: 'text', analyzer: 'keyword' },
      smooch: { type: 'integer' },
      flag_adult: { type: 'integer' },
      flag_spoof: { type: 'integer' },
      flag_medical: { type: 'integer' },
      flag_violence: { type: 'integer' },
      flag_racy: { type: 'integer' },
      flag_spam: { type: 'integer' }
    }
  }

  attribute :rules, Array, mapping: { type: 'keyword' }

  attribute :linked_items_count, Integer, mapping: { type: 'long' }

  attribute :last_seen, Integer, mapping: { type: 'long' }

  attribute :share_count, Integer, mapping: { type: 'long' }

  attribute :demand, Integer, mapping: { type: 'long' }

  def set_es_annotated(obj)
    self.send("annotated_type=", obj.class.name)
    self.send("annotated_id=", obj.id)
  end
end
