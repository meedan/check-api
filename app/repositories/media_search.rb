class MediaSearch

  include CheckElasticSearchModel

  mapping do
    indexes :annotation_type, { type: 'text' }
    indexes :team_id, { type: 'integer' }
    indexes :project_id, { type: 'integer' }
    indexes :annotated_type, { type: 'text' }
    indexes :annotated_id, { type: 'integer' }
    indexes :parent_id, { type: 'integer' }
    indexes :associated_type, { type: 'keyword' }
    indexes :title, { type: 'text', analyzer: 'check' }
    indexes :description, { type: 'text', analyzer: 'check' }
    indexes :analysis_title, { type: 'text', analyzer: 'check' }
    indexes :sort_title, { type: 'keyword' }
    indexes :analysis_description, { type: 'text', analyzer: 'check' }
    indexes :quote, { type: 'text', analyzer: 'check' }
    indexes :archived, { type: 'integer' }
    indexes :sources_count, { type: 'integer' }
    indexes :user_id, { type: 'integer' }
    indexes :read, { type: 'integer' }
    indexes :created_at, { type: 'date' }
    indexes :updated_at, { type: 'date' }
    indexes :published_at, { type: 'date' }
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
    indexes :task_comments, {
      type: 'nested',
      properties: {
        id: { type: 'text'},
        team_task_id: { type: 'integer'},
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
        id: { type: 'integer' },
        fieldset: { type: 'text' },
        field_type: { type: 'text' },
        team_task_id: { type: 'integer' },
        value: { type: 'text', analyzer: 'check', fields: { raw: { type: 'text', analyzer: 'keyword' } } },
        date_value: { type: 'date' },
      }
    }

    indexes :linked_items_count, { type: 'long' }

    indexes :last_seen, { type: 'long' }

    indexes :share_count, { type: 'long' }

    indexes :demand, { type: 'long' }

    indexes :assigned_user_ids, { type: 'long' }

    indexes :report_status, { type: 'long' } # 0 = unpublished, 1 = paused, 2 = published

    indexes :tags_as_sentence, { type: 'long' } # tags count is indexed

    indexes :media_published_at, { type: 'long' }

    indexes :reaction_count, { type: 'long' }

    indexes :comment_count, { type: 'long' }

    indexes :related_count, { type: 'long' }

    indexes :suggestions_count, { type: 'long' }

    indexes :source_id, { type: 'integer' }

    indexes :status_index, { type: 'long' } # For sorting - indexes the status index in the list of status ids

    indexes :type_of_media, { type: 'long' } # For sorting - indexes the type index in the list of media types

    indexes :url, { type: 'text', analyzer: 'check' }

    indexes :channel, { type: 'integer' }

    indexes :extracted_text, { type: 'text', analyzer: 'check' }

    indexes :creator_name, { type: 'keyword', normalizer: 'check', fields: { raw: { type: 'text', analyzer: 'check' } } }
  end
end
