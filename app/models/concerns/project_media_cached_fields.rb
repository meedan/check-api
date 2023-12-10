require 'active_support/concern'

module ProjectMediaCachedFields
  extend ActiveSupport::Concern

  # FIXME: Need to get this value from some API and update it periodically
  def virality
    0
  end

  module ClassMethods
    def title_or_description_update
      [
        {
          model: ClaimDescription,
          affected_ids: proc { |cd| [cd.project_media] },
          events: {
            save: :recalculate
          }
        },
        {
          model: FactCheck,
          affected_ids: proc { |fc| [fc.claim_description.project_media] },
          events: {
            save: :recalculate
          }
        },
        {
          model: DynamicAnnotation::Field,
          if: proc { |f| f.field_name == 'metadata_value' },
          affected_ids: proc { |f|
            if ['Media', 'Link'].include?(f.annotation.annotated_type)
              ProjectMedia.where(media_id: f.annotation.annotated_id).map(&:id)
            end
          },
          events: {
            save: :recalculate
          }
        },
        {
          model: DynamicAnnotation::Field,
          if: proc { |f| ['title', 'content', 'file_title'].include?(f.field_name) && f.annotation.annotation_type == 'verification_status' && !f.value.blank? },
          affected_ids: proc { |f| [f.annotation.annotated_id] },
          events: {
            save: :recalculate
          }
        },
        {
          model: ProjectMedia,
          if: proc { |pm| pm.saved_changes[:custom_title].present? || pm.saved_changes[:title_field].present? },
          affected_ids: proc { |pm| [pm.id] },
          events: {
            save: :recalculate
          }
        }
      ]
    end
  end

  included do

    SIMILARITY_EVENT = {
      model: Relationship,
      if: proc { |r| !r.is_default? },
      affected_ids: proc { |r| [r.source_id, r.target_id] },
      events: {
        save: :recalculate,
        destroy: :recalculate
      }
    }

    FACT_CHECK_EVENT = {
      model: FactCheck,
      affected_ids: proc { |fc| [fc.claim_description.project_media] },
      events: {
        save: :recalculate
      }
    }

    { is_suggested: Relationship.suggested_type, is_confirmed: Relationship.confirmed_type }.each do |field_name, _type|
      cached_field field_name,
        start_as: false,
        recalculate: :"recalculate_#{field_name}",
        update_on: [SIMILARITY_EVENT]
    end

    cached_field :linked_items_count,
      start_as: proc { |pm| pm.media.type == 'Blank' ? 0 : 1 },
      update_es: true,
      recalculate: :recalculate_linked_items_count,
      update_on: [SIMILARITY_EVENT]

    cached_field :suggestions_count,
      start_as: 0,
      update_es: true,
      recalculate: :recalculate_suggestions_count,
      update_on: [SIMILARITY_EVENT]

    cached_field :related_count,
      start_as: 0,
      update_es: true,
      recalculate: :recalculate_related_count,
      update_on: [
        {
          model: Relationship,
          if: proc { |r| r.is_default? },
          affected_ids: proc { |r| [r.source_id, r.target_id] },
          events: {
            save: :recalculate,
            destroy: :recalculate
          }
        }
      ]

    cached_field :requests_count,
      start_as: 0,
      recalculate: :recalculate_requests_count,
      update_on: [
        {
          model: TiplineRequest,
          if: proc { |tr| tr.associated_type == 'ProjectMedia' },
          affected_ids: proc { |tr| [tr.associated_id] },
          events: {
            create: :recalculate,
            destroy: :recalculate,
          }
        }
      ]

    cached_field :demand,
      start_as: 0,
      update_es: true,
      recalculate: :recalculate_demand,
      update_on: [
        {
          model: TiplineRequest,
          if: proc { |tr| tr.associated_type == 'ProjectMedia' },
          affected_ids: proc { |tr| tr.associated.related_items_ids },
          events: {
            create: :recalculate,
          }
        },
        {
          model: Relationship,
          if: proc { |r| r.is_confirmed? },
          affected_ids: proc { |r| [r.source&.related_items_ids, r.target_id].flatten.reject{ |id| id.blank? }.uniq },
          events: {
            save: :recalculate,
            destroy: :recalculate
          }
        }
      ]

    cached_field :last_seen,
      start_as: proc { |pm| pm.created_at.to_i },
      update_es: true,
      update_pg: true,
      recalculate: :recalculate_last_seen,
      update_on: [
        {
          model: TiplineRequest,
          if: proc { |tr| tr.associated_type == 'ProjectMedia' },
          affected_ids: proc { |tr| tr.associated&.related_items_ids.to_a },
          events: {
            create: :recalculate,
          }
        },
        {
          model: Relationship,
          if: proc { |r| r.is_confirmed? },
          affected_ids: proc { |r| r.source&.related_items_ids.to_a },
          events: {
            save: :recalculate,
            destroy: :recalculate
          }
        }
      ]

    cached_field :fact_check_title,
      start_as: nil,
      recalculate: :recalculate_fact_check_title,
      update_on: [FACT_CHECK_EVENT]

    cached_field :fact_check_summary,
      start_as: nil,
      recalculate: :recalculate_fact_check_summary,
      update_on: [FACT_CHECK_EVENT]

    cached_field :fact_check_url,
      start_as: nil,
      recalculate: :recalculate_fact_check_url,
      update_on: [FACT_CHECK_EVENT]

    cached_field :fact_check_published_on,
      start_as: 0,
      update_es: true,
      recalculate: :recalculate_fact_check_published_on,
      update_on: [FACT_CHECK_EVENT]

    cached_field :description,
      recalculate: :recalculate_description,
      update_on: title_or_description_update

    cached_field :title,
      update_es: true,
      es_field_name: :title_index,
      recalculate: :recalculate_title,
      update_on: title_or_description_update

    cached_field :status,
      update_es: :cached_field_status_es,
      es_field_name: :status_index,
      recalculate: :recalculate_status,
      update_on: [
        {
          model: DynamicAnnotation::Field,
          if: proc { |f| f.field_name == 'verification_status_status' },
          affected_ids: proc { |f| [f.annotation&.annotated_id.to_i] },
          events: {
            save: :cached_field_project_media_status_save,
          }
        }
      ]

    [:share, :reaction, :comment].each do |metric|
      cached_field "#{metric}_count".to_sym,
        start_as: 0,
        update_es: true,
        recalculate: :"recalculate_#{metric}",
        update_on: [
          {
            model: DynamicAnnotation::Field,
            if: proc { |f| f.field_name == 'metrics_data' },
            affected_ids: proc { |f| [f.annotation&.annotated_id.to_i] },
            events: {
              save: :recalculate
            }
          }
        ]
    end

    cached_field :report_status,
      start_as: proc { |_pm| 'unpublished' },
      update_es: :cached_field_report_status_es,
      recalculate: :recalculate_report_status,
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'report_design' },
          affected_ids: proc { |d| d.annotated.related_items_ids },
          events: {
            save: :cached_field_project_media_report_status_save,
          }
        },
        SIMILARITY_EVENT
      ]

    cached_field :tags_as_sentence,
      start_as: proc { |_pm| '' },
      update_es: :cached_field_tags_as_sentence_es,
      recalculate: :recalculate_tags_as_sentence,
      expires_in: 5.years,
      update_on: [
        {
          model: Tag,
          affected_ids: proc { |t| [t.annotated_id.to_i] },
          events: {
            save: :cached_field_project_media_tags_as_sentence_save,
            destroy: :cached_field_project_media_tags_as_sentence_destroy,
          }
        }
      ]

    cached_field :sources_as_sentence,
      start_as: proc { |_pm| '' },
      recalculate: :recalculate_sources_as_sentence,
      update_on: [
        {
          model: ProjectMedia,
          affected_ids: proc { |pm| [pm.id].concat(
            Relationship.where(target_id: pm.id).where('relationship_type = ?', Relationship.confirmed_type.to_yaml)
            .map(&:source_id)
            )},
          if: proc { |pm| pm.saved_change_to_source_id? },
          events: {
            save: :recalculate,
          }
        },
        {
          model: Relationship,
          affected_ids: proc { |r| [r.source_id] },
          events: {
            save: :recalculate,
            destroy: :recalculate
          }
        },
        {
          model: Source,
          if: proc { |s| s.saved_change_to_name? },
          affected_ids: proc { |s| s.project_media_ids.concat(
            Relationship.where(target_id: s.project_media_ids).where('relationship_type = ?', Relationship.confirmed_type.to_yaml)
            .map(&:source_id)
            )},
          events: {
            update: :recalculate,
          }
        }
      ]

    cached_field :media_published_at,
      start_as: proc { |pm| pm.published_at.to_i },
      update_es: true,
      recalculate: :recalculate_media_published_at,
      update_on: [
        {
          model: Link,
          affected_ids: proc { |m| m.project_media_ids },
          events: {
            save: :recalculate
          }
        }
      ]

    cached_field :published_by,
      start_as: {},
      update_es: :cached_field_published_by_es,
      recalculate: :recalculate_published_by,
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'report_design' },
          affected_ids: proc { |d| d.annotated_id },
          events: {
            save: :cached_field_project_media_published_by_save,
          }
        },
        {
          model: User,
          affected_ids: proc { |u|
            conditions = {
              annotation_type: 'report_design',
              annotator_type: 'User',
              annotator_id: u.id,
              annotated_type: 'ProjectMedia'
            }
            Dynamic.where(conditions).where('data LIKE ?', '%state: published%').map(&:annotated_id)
          },
          if: proc { |u| u.saved_change_to_name? },
          events: {
            update: :cached_field_project_media_published_by_update,
          }
        },
      ]

    cached_field :type_of_media,
      start_as: proc { |pm| pm.media.type },
      recalculate: :recalculate_type_of_media,
      update_on: [] # Should never change

    cached_field :added_as_similar_by_name,
      start_as: nil,
      recalculate: :recalculate_added_as_similar_by_name,
      update_on: [
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          events: {
            create: :cached_field_project_media_added_as_similar_by_name_create,
            destroy: :cached_field_project_media_added_as_similar_by_name_destroy,
          }
        }
      ]

    cached_field :confirmed_as_similar_by_name,
      start_as: nil,
      recalculate: :recalculate_confirmed_as_similar_by_name,
      update_on: [
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          if: proc { |r| r.is_being_confirmed? },
          events: {
            save: :recalculate,
          }
        },
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          events: {
            destroy: :cached_field_project_media_confirmed_as_similar_by_name_destroy,
          }
        }
      ]

    cached_field :folder,
      start_as: proc { |pm| pm.project&.title.to_s },
      recalculate: :recalculate_folder,
      update_on: [
        {
          model: ProjectMedia,
          affected_ids: proc { |pm| [pm.id] },
          if: proc { |pm| pm.saved_change_to_project_id? },
          events: {
            save: :recalculate,
          }
        },
        {
          model: Project,
          affected_ids: proc { |p| p.project_media_ids.empty? ? p.project_media_ids_were.to_a : p.project_media_ids },
          events: {
            save: :cached_field_project_media_folder_save,
          }
        }
      ]

    cached_field :show_warning_cover,
      start_as: false,
      recalculate: :recalculate_show_warning_cover,
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'flag' },
          affected_ids: proc { |d| d.annotated_id },
          events: {
            save: :cached_field_project_media_show_warning_cover_save,
          }
        },
      ]

    cached_field :picture,
      start_as: proc { |pm| pm.lead_image },
      recalculate: :recalculate_picture,
      update_on: [] # Never changes

    cached_field :team_name,
      start_as: proc { |pm| pm.team.name },
      recalculate: :recalculate_team_name,
      update_on: [] # Never changes

    cached_field :creator_name,
      start_as: proc { |pm| pm.get_creator_name },
      update_es: true,
      recalculate: :recalculate_creator_name,
      update_on: [
        {
          model: User,
          affected_ids: proc { |u|
            u.project_medias.where("channel->>'main'IN (?)", [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::BROWSER_EXTENSION].map(&:to_s)).map(&:id)
          },
          if: proc { |u| u.saved_change_to_name? },
          events: {
            update: :cached_field_project_media_creator_name_update,
          }
        },
      ]

    cached_field :positive_tipline_search_results_count,
      update_es: true,
      recalculate: :recalculate_positive_tipline_search_results_count,
      update_on: [
        {
          model: TiplineRequest,
          if: proc { |tr| tr.smooch_request_type == 'relevant_search_result_requests' },
          affected_ids: proc { |tr| [tr.associated_id] },
          events: {
            save: :recalculate,
            destroy: :recalculate,
          }
        }
      ]

    cached_field :tipline_search_results_count,
      update_es: true,
      recalculate: :recalculate_tipline_search_results_count,
      update_on: [
        {
          model: TiplineRequest,
          if: proc { |tr| ['relevant_search_result_requests', 'irrelevant_search_result_requests', 'timeout_search_requests'].include?(tr.smooch_request_type) },
          affected_ids: proc { |tr| [tr.associated_id] },
          events: {
            save: :recalculate,
            destroy: :recalculate,
          }
        }
      ]

    def recalculate_linked_items_count
      count = Relationship.send('confirmed').where(source_id: self.id).count
      count += 1 unless self.media.type == 'Blank'
      count
    end

    def recalculate_suggestions_count
      Relationship.send('suggested').where(source_id: self.id).count
    end

    def recalculate_is_suggested
      Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml).where(target_id: self.id).exists?
    end

    def recalculate_is_confirmed
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(target_id: self.id).exists?
    end

    def recalculate_related_count
      Relationship.default.where('source_id = ? OR target_id = ?', self.id, self.id).count
    end

    def recalculate_requests_count
      TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: self.id).count
    end

    def recalculate_demand
      n = 0
      self.related_items_ids.collect{ |id| n += ProjectMedia.new(id: id).requests_count }
      n
    end

    def recalculate_last_seen
      # If it’s a main/parent item, last_seen is related to any tipline request to that own ProjectMedia or any similar/child ProjectMedia
      # If it’s not a main item (so, single or child, a.k.a. “confirmed match” or “suggestion”), then last_seen is related only to tipline requests related to that ProjectMedia.
      ids = self.is_parent ? self.related_items_ids : self.id
      v1 = TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: ids).order('created_at DESC').first&.created_at || 0
      v2 = ProjectMedia.where(id: ids).order('created_at DESC').first&.created_at || 0
      [v1, v2].max.to_i
    end

    def recalculate_fact_check_title
      self.claim_description&.fact_check&.title
    end

    def recalculate_fact_check_summary
      self.claim_description&.fact_check&.summary
    end

    def recalculate_fact_check_url
      self.claim_description&.fact_check&.url
    end

    def recalculate_fact_check_published_on
      self.claim_description&.fact_check&.updated_at.to_i
    end

    def recalculate_description
      self.get_description
    end

    def recalculate_title
      self.get_title
    end

    def recalculate_status
      self.last_verification_status
    end

    def recalculate_share
      recalculate_metric_fields(:share)
    end

    def recalculate_reaction
      recalculate_metric_fields(:reaction)
    end

    def recalculate_comment
      recalculate_metric_fields(:comment)
    end

    def recalculate_metric_fields(metric)
      begin JSON.parse(self.get_annotations('metrics').last.load.get_field_value('metrics_data'))['facebook']["#{metric}_count"] rescue 0 end
    end

    def recalculate_report_status
      Relationship.confirmed_parent(self).get_dynamic_annotation('report_design')&.get_field_value('state') || 'unpublished'
    end

    def recalculate_tags_as_sentence
      self.get_annotations('tag').map(&:load).map(&:tag_text).uniq.join(', ')
    end

    def recalculate_sources_as_sentence
      self.get_project_media_sources
    end

    def recalculate_media_published_at
      self.published_at.to_i
    end

    def recalculate_published_by
      d = self.get_dynamic_annotation('report_design')
      annotator = d && d['data']['state'] == 'published' ? d.annotator : nil
      annotator.nil? ? {} : { annotator.id => annotator.name }
    end

    def recalculate_type_of_media
      self.media.type
    end

    def recalculate_added_as_similar_by_name
      user = Relationship.confirmed.where(target_id: self.id).last&.user
      user && user == BotUser.alegre_user ? 'Check' : user&.name
    end

    def recalculate_confirmed_as_similar_by_name
      # Could also get it from version:
      # Version.from_partition(pm.team_id).where(item_type: 'Relationship', item_id: r.id.to_s)
      # .where("object_changes LIKE '%suggested_sibling%confirmed_sibling%'").last&.user&.name
      r = Relationship.confirmed.where(target_id: self.id).last
      r.nil? ? nil : User.find_by_id(r.confirmed_by.to_i)&.name
    end

    def recalculate_folder
      self.project&.title.to_s
    end

    def recalculate_show_warning_cover
      self.get_dynamic_annotation('flag')&.get_field_value('show_cover') || false
    end

    def recalculate_picture
      self.lead_image
    end

    def recalculate_team_name
      self.team.name
    end

    def recalculate_creator_name
      self.get_creator_name
    end

    def cached_field_status_es(value)
      self.status_ids.index(value)
    end

    def cached_field_report_status_es(value)
      ['unpublished', 'paused', 'published'].index(value)
    end

    def cached_field_tags_as_sentence_es(value)
      value.split(', ').uniq.size
    end

    def cached_field_published_by_es(value)
      value.keys.first || 0
    end

    def recalculate_positive_tipline_search_results_count
      TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: self.id, smooch_request_type: 'relevant_search_result_requests').count
    end

    def recalculate_tipline_search_results_count
      types = ["relevant_search_result_requests", "irrelevant_search_result_requests", "timeout_search_requests"]
      TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: self.id, smooch_request_type: types).count
    end
  end

  DynamicAnnotation::Field.class_eval do
    def cached_field_project_media_status_save(_target)
      self.value
    end
  end

  Dynamic.class_eval do
    def cached_field_project_media_report_status_save(_target)
      self.data.with_indifferent_access[:state]
    end

    def cached_field_project_media_published_by_save(_target)
      annotator = self['data']['state'] == 'published' ? self.annotator : nil
      annotator.nil? ? {} : { annotator.id => annotator.name }
    end

    def cached_field_project_media_show_warning_cover_save(_target)
      self.data.with_indifferent_access[:show_cover]
    end
  end

  Relationship.class_eval do
    def cached_field_project_media_added_as_similar_by_name_create(_target)
      self.user && self.user == BotUser.alegre_user ? 'Check' : self.user&.name
    end

    def cached_field_project_media_added_as_similar_by_name_destroy(_target)
      nil
    end

    def cached_field_project_media_confirmed_as_similar_by_name_destroy(_target)
      nil
    end
  end

  User.class_eval do
    def cached_field_project_media_published_by_update(_target)
      { self.id => self.name }
    end

    def cached_field_project_media_creator_name_update(_target)
      self.name
    end
  end

  Project.class_eval do
    def cached_field_project_media_folder_save(_target)
      self.title
    end
  end

  Tag.class_eval do
    def cached_field_project_media_tags_as_sentence_save(target)
      target.tags_as_sentence.split(', ').concat([self.tag_text]).uniq.join(', ')
    end

    def cached_field_project_media_tags_as_sentence_destroy(target)
      target.tags_as_sentence.split(', ').reject{ |tt| tt == self.tag_text }.uniq.join(', ')
    end
  end
end
