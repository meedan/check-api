class MediaSearch

  include CheckElasticSearchModel

  mapping do
    indexes :team_id, { type: 'integer' }
    indexes :annotated_type, { type: 'text' }
    indexes :annotated_id, { type: 'integer' }
    indexes :parent_id, { type: 'integer' }
    indexes :associated_type, { type: 'keyword' }
    indexes :title, { type: 'text', analyzer: 'check' }
    indexes :description, { type: 'text', analyzer: 'check' }
    indexes :analysis_title, { type: 'text', analyzer: 'check' }
    indexes :title_index, { type: 'keyword', normalizer: 'check' } # For sorting by item title
    indexes :analysis_description, { type: 'text', analyzer: 'check' }
    indexes :archived, { type: 'integer' }
    indexes :sources_count, { type: 'integer' }
    indexes :user_id, { type: 'integer' }
    indexes :read, { type: 'integer' }
    indexes :created_at, { type: 'date' }
    indexes :updated_at, { type: 'date' }
    indexes :language, { type: 'text', analyzer: 'keyword' }
    indexes :tags, {
      type: 'nested',
      properties: {
        id: { type: 'integer'},
        tag: { type: 'text', analyzer: 'check', fields: { raw: { type: 'text' } } }
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
        numeric_value: { type: 'integer' },
        date_value: { type: 'date' },
      }
    }

    indexes :requests, {
      type: 'nested',
      properties: {
        id: { type: 'integer'},
        username: { type: 'text', analyzer: 'check'},
        identifier: { type: 'text', analyzer: 'check'},
        content: { type: 'text', analyzer: 'check'},
        language: { type: 'keyword', normalizer: 'check' },
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

    indexes :report_published_at, { type: 'long' }

    indexes :published_by, { type: 'long' }

    indexes :annotated_by, { type: 'long' }

    indexes :reaction_count, { type: 'long' }

    indexes :related_count, { type: 'long' }

    indexes :suggestions_count, { type: 'long' }

    indexes :source_id, { type: 'integer' }

    indexes :status_index, { type: 'long' } # For sorting - indexes the status index in the list of status ids

    indexes :type_of_media, { type: 'long' } # For sorting - indexes the type index in the list of media types

    indexes :url, { type: 'text', analyzer: 'check' }

    indexes :channel, { type: 'integer' }

    indexes :extracted_text, { type: 'text', analyzer: 'check' }

    indexes :creator_name, { type: 'keyword', normalizer: 'check', fields: { raw: { type: 'text', analyzer: 'check' } } }

    indexes :cluster_size, { type: 'long' }

    indexes :claim_description_content, { type: 'text', analyzer: 'check' }

    indexes :claim_description_context, { type: 'text', analyzer: 'check' }

    indexes :fact_check_title, { type: 'text', analyzer: 'check' }

    indexes :fact_check_summary, { type: 'text', analyzer: 'check' }

    indexes :fact_check_url, { type: 'text', analyzer: 'check' }

    indexes :cluster_first_item_at, { type: 'long' }

    indexes :cluster_last_item_at, { type: 'long' }

    indexes :cluster_published_reports, { type: 'long' }

    indexes :cluster_published_reports_count, { type: 'long' }

    indexes :cluster_requests_count, { type: 'long' }

    indexes :cluster_teams, { type: 'long' }

    indexes :fact_check_languages, { type: 'keyword', normalizer: 'check' }

    indexes :source_name, { type: 'text', analyzer: 'check' }

    indexes :unmatched, { type: 'long' }

    indexes :report_language, { type: 'keyword', normalizer: 'check' }

    indexes :fact_check_published_on, { type: 'long' }

    indexes :positive_tipline_search_results_count, { type: 'long' }

    indexes :negative_tipline_search_results_count, { type: 'long' }

    indexes :tipline_search_results_count, { type: 'long' }

    indexes :explainer_title, { type: 'text', analyzer: 'check' }
  end
end
