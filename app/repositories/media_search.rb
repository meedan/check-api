class MediaSearch

  include CheckElasticSearchModel

  mapping do
    indexes :annotation_type, { type: 'text' }
    indexes :team_id, { type: 'integer' }
    indexes :project_id, { type: 'integer' }
    indexes :annotated_type, { type: 'text' }
    indexes :annotated_id, { type: 'integer' }
    indexes :associated_type, { type: 'keyword' }
    indexes :relationship_sources, { type: 'text' }
    indexes :title, { type: 'text', analyzer: 'check' }
    indexes :description, { type: 'text', analyzer: 'check' }
    indexes :quote, { type: 'text', analyzer: 'check' }
    indexes :archived, { type: 'integer' }
    indexes :sources_count, { type: 'integer' }
    indexes :user_id, { type: 'integer' }
    indexes :read, { type: 'integer' }
    indexes :created_at, { type: 'date' }
    indexes :updated_at, { type: 'date' }
    indexes :accounts, {
      type: 'nested',
      properties: {
        id: { type: 'integer'},
        username: { type: 'text', analyzer: 'check'},
        title: { type: 'text', analyzer: 'check'},
        description: { type: 'text', analyzer: 'check'}
      }
    }
    indexes :comments, {
      type: 'nested',
      properties: {
        id: { type: 'text'},
        text: { type: 'text', analyzer: 'check'}
      }
    }
    indexes :tags, {
      type: 'nested',
      properties: {
        id: { type: 'integer'},
        tag: { type: 'text', analyzer: 'check', fields: { raw: { type: 'text' } } }
      }
    }
    indexes :dynamics, {
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

    indexes :task_responses, {
      type: 'nested',
      properties: {
        id: { type: 'integer'},
        team_task_id: { type: 'integer'},
        fieldset: { type: 'text' },
        field_name: { type: 'text' },
        value: { type: 'text', analyzer: 'keyword'}
      }
    }

    indexes :rules, { type: 'keyword' }

    indexes :linked_items_count, { type: 'long' }

    indexes :last_seen, { type: 'long' }

    indexes :share_count, { type: 'long' }

    indexes :demand, { type: 'long' }
  end
end
