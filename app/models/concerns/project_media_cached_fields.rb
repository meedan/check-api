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
        }
      ]
    end

    def cached_field_es_value(target, name, value)
      case name.to_s
      when 'report_status'
        ['unpublished', 'paused', 'published'].index(value)
      when 'status'
        target.status_ids.index(value)
      when 'tags_as_sentence'
        value.split(', ').uniq.size
      when 'published_by'
        value.keys.first || 0
      when 'type_of_media'
        Media.types.index(value)
      else
        value
      end
    end

    def cached_field_recalculate_linked_items_count(target, obj)
      Relationship.send('confirmed').where(source_id: target.id).count
    end

    def cached_field_recalculate_suggestions_count(target, obj)
      Relationship.send('suggested').where(source_id: target.id).count
    end

    def cached_field_recalculate_is_suggested(target, obj)
      Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml).where(target_id: target.id).exists?
    end

    def cached_field_recalculate_is_confirmed(target, obj)
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(target_id: target.id).exists?
    end

    def cached_field_recalculate_related_count(target, obj)
      Relationship.default.where('source_id = ? OR target_id = ?', target.id, target.id).count
    end

    def cached_field_recalculate_requests_count(target, obj)
      Dynamic.where(annotation_type: 'smooch', annotated_id: target.id).count
    end

    def cached_field_update_on_create_dynamic_requests_count(target, obj)
      target.requests_count + 1
    end

    def cached_field_update_on_destroy_dynamic_requests_count(target, obj)
      target.requests_count - 1
    end

    def cached_field_recalculate_demand(target, obj)
      n = 0
      target.related_items_ids.collect{ |id| n += ProjectMedia.new(id: id).requests_count }
      n
    end

    def cached_field_update_on_create_dynmic_demand(target, obj)
      target.demand + 1
    end

    def cached_field_recalculate_last_seen(target, obj)
      (Dynamic.where(annotation_type: 'smooch', annotated_id: target.related_items_ids).order('created_at DESC').first&.created_at || ProjectMedia.find_by_id(target.id)&.created_at).to_i
    end

    def cached_field_update_on_create_dynamic_last_seen(target, obj)
      obj.created_at.to_i
    end

    def cached_field_update_on_save_relationship_last_seen(target, obj)
      [obj.source&.last_seen.to_i, obj.target&.last_seen.to_i].max
    end

    def cached_field_recalculate_fact_check_title(target, obj)
      target.claim_description&.fact_check&.title
    end

    def cached_field_recalculate_fact_check_summary(target, obj)
      target.claim_description&.fact_check&.summary
    end

    def cached_field_recalculate_fact_check_url(target, obj)
      target.claim_description&.fact_check&.url
    end

    def cached_field_recalculate_fact_check_published_on(target, obj)
      target.claim_description&.fact_check&.updated_at.to_i
    end

    def cached_field_recalculate_description(target, obj)
      target.get_description
    end

    def cached_field_recalculate_title(target, obj)
      target.get_title
    end

    def cached_field_recalculate_status(target, obj)
      target.last_verification_status
    end

    def cached_field_update_on_save_dynamic_annotation_field_status(target, obj)
      obj.value
    end

    def cached_field_recalculate_share(target, obj)
      metric = :share
      begin JSON.parse(target.get_annotations('metrics').last.load.get_field_value('metrics_data'))['facebook']["#{metric}_count"] rescue 0 end
    end

    def cached_field_recalculate_reaction(target, obj)
      metric = :reaction
      begin JSON.parse(target.get_annotations('metrics').last.load.get_field_value('metrics_data'))['facebook']["#{metric}_count"] rescue 0 end
    end

    def cached_field_recalculate_comment(target, obj)
      metric = :comment
      begin JSON.parse(target.get_annotations('metrics').last.load.get_field_value('metrics_data'))['facebook']["#{metric}_count"] rescue 0 end
    end

    def cached_field_recalculate_report_status(target, obj)
      Relationship.confirmed_parent(target).get_dynamic_annotation('report_design')&.get_field_value('state') || 'unpublished'
    end

    def cached_field_update_on_save_dynamic_report_status(target, obj)
      obj.data.with_indifferent_access[:state]
    end

    def cached_field_recalculate_tags_as_sentence(target, obj)
      target.get_annotations('tag').map(&:load).map(&:tag_text).uniq.join(', ')
    end

    def cached_field_update_on_save_tag_tags_as_sentence(target, obj)
      target.tags_as_sentence.split(', ').concat([obj.tag_text]).uniq.join(', ')
    end

    def cached_field_update_on_destroy_tag_tags_as_sentence(target, obj)
      target.tags_as_sentence.split(', ').reject{ |tt| tt == obj.tag_text }.uniq.join(', ')
    end

    def cached_field_recalculate_sources_as_sentence(target, obj)
      target.get_project_media_sources
    end

    def cached_field_recalculate_media_published_at(target, obj)
      target.published_at.to_i
    end

    def cached_field_recalculate_published_by(target, obj)
      d = target.get_dynamic_annotation('report_design')
      annotator = d && d['data']['state'] == 'published' ? d.annotator : nil
      value = annotator.nil? ? {} : { annotator.id => annotator.name }
    end

    def cached_field_update_on_save_dynmic_published_by(target, obj)
      annotator = obj['data']['state'] == 'published' ? obj.annotator : nil
      annotator.nil? ? {} : { annotator.id => annotator.name }
    end

    def cached_field_update_on_update_user_published_by(target, obj)
      { obj.id => obj.name }
    end

    def cached_field_recalculate_type_of_media(target, obj)
      target.media.type
    end

    def cached_field_recalculate_added_as_similar_by_name(target, obj)
      user = Relationship.confirmed.where(target_id: target.id).last&.user
      user && user == BotUser.alegre_user ? 'Check' : user&.name
    end

    def cached_field_update_on_create_relationship_added_as_similar_by_name(target, obj)
      obj.user && obj.user == BotUser.alegre_user ? 'Check' : obj.user&.name
    end

    def cached_field_update_on_destroy_relationship_added_as_similar_by_name(target, obj)
      nil
    end

    def cached_field_recalculate_confirmed_as_similar_by_name(target, obj)
      # Could also get it from version:
      # Version.from_partition(pm.team_id).where(item_type: 'Relationship', item_id: r.id.to_s)
      # .where("object_changes LIKE '%suggested_sibling%confirmed_sibling%'").last&.user&.name
      r = Relationship.confirmed.where(target_id: target.id).last
      r.nil? ? nil : User.find_by_id(r.confirmed_by.to_i)&.name
    end

    def cached_field_update_on_save_relationship_confirmed_as_similar_by_name(target, obj)
      User.current&.name
    end

    def cached_field_update_on_destroy_relationship_confirmed_as_similar_by_name(target, obj)
      nil
    end

    def cached_field_recalculate_folder(target, obj)
      target.project&.title.to_s
    end

    def cached_field_update_on_save_project_folder(target, obj)
      obj.title
    end

    def cached_field_recalculate_show_warning_cover(target, obj)
      target.get_dynamic_annotation('flag')&.get_field_value('show_cover') || false
    end

    def cached_field_update_on_save_dynmic_show_warning_cover(target, obj)
      obj.data.with_indifferent_access[:show_cover]
    end

    def cached_field_recalculate_picture(target, obj)
      target.lead_image
    end

    def cached_field_recalculate_team_name(target, obj)
      target.team.name
    end

    def cached_field_recalculate_creator_name(target, obj)
      target.get_creator_name
    end

    def cached_field_update_on_update_user_creator_name(target, obj)
      obj.name
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

    { linked_items_count: 'confirmed', suggestions_count: 'suggested' }.each do |field_name, type|
      cached_field field_name,
        start_as: 0,
        update_es: true,
        update_on: [SIMILARITY_EVENT]
    end

    { is_suggested: Relationship.suggested_type, is_confirmed: Relationship.confirmed_type }.each do |field_name, type|
      cached_field field_name,
        start_as: false,
        update_on: [SIMILARITY_EVENT]
    end


    cached_field :related_count,
      start_as: 0,
      update_es: true,
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
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' && d.annotated_type == 'ProjectMedia' },
          affected_ids: proc { |d| [d.annotated_id] },
          events: {
            create: :update_on,
            destroy: :update_on,
          }
        }
      ]

    cached_field :demand,
      start_as: 0,
      update_es: true,
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' && d.annotated_type == 'ProjectMedia' },
          affected_ids: proc { |d| d.annotated.related_items_ids },
          events: {
            create: :update_on,
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
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' && d.annotated_type == 'ProjectMedia' },
          affected_ids: proc { |d| d.annotated&.related_items_ids.to_a },
          events: {
            create: :update_on,
          }
        },
        {
          model: Relationship,
          if: proc { |r| r.is_confirmed? },
          affected_ids: proc { |r| r.source&.related_items_ids.to_a },
          events: {
            save: :update_on,
            destroy: :recalculate
          }
        }
      ]

    cached_field :fact_check_title,
      start_as: nil,
      update_on: [FACT_CHECK_EVENT]

    cached_field :fact_check_summary,
      start_as: nil,
      update_on: [FACT_CHECK_EVENT]

    cached_field :fact_check_url,
      start_as: nil,
      update_on: [FACT_CHECK_EVENT]

    cached_field :fact_check_published_on,
      start_as: 0,
      update_on: [FACT_CHECK_EVENT]

    cached_field :description,
      update_on: title_or_description_update

    cached_field :title,
      update_es: true,
      es_field_name: :title_index,
      update_on: title_or_description_update

    cached_field :status,
      update_es: true,
      es_field_name: :status_index,
      update_on: [
        {
          model: DynamicAnnotation::Field,
          if: proc { |f| f.field_name == 'verification_status_status' },
          affected_ids: proc { |f| [f.annotation&.annotated_id.to_i] },
          events: {
            save: :update_on,
          }
        }
      ]

    [:share, :reaction, :comment].each do |metric|
      cached_field "#{metric}_count".to_sym,
        start_as: 0,
        update_es: true,
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
      update_es: true,
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'report_design' },
          affected_ids: proc { |d| d.annotated.related_items_ids },
          events: {
            save: :update_on,
          }
        },
        SIMILARITY_EVENT
      ]

    cached_field :tags_as_sentence,
      start_as: proc { |_pm| '' },
      update_es: true,
      update_on: [
        {
          model: Tag,
          affected_ids: proc { |t| [t.annotated_id.to_i] },
          events: {
            save: :update_on,
            destroy: :update_on,
          }
        }
      ]

    cached_field :sources_as_sentence,
      start_as: proc { |_pm| '' },
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
      update_es: true,
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'report_design' },
          affected_ids: proc { |d| d.annotated_id },
          events: {
            save: :update_on,
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
            update: :update_on,
          }
        },
      ]

    cached_field :type_of_media,
      start_as: proc { |pm| pm.media.type },
      update_on: [] # Should never change

    cached_field :added_as_similar_by_name,
      start_as: nil,
      update_on: [
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          events: {
            create: :update_on,
            destroy: :update_on,
          }
        }
      ]

    cached_field :confirmed_as_similar_by_name,
      start_as: nil,
      update_on: [
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          if: proc { |r| r.is_being_confirmed? },
          events: {
            save: :update_on,
          }
        },
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          events: {
            destroy: :update_on,
          }
        }
      ]

    cached_field :folder,
      start_as: proc { |pm| pm.project&.title.to_s },
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
            save: :update_on,
          }
        }
      ]

    cached_field :show_warning_cover,
      start_as: false,
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'flag' },
          affected_ids: proc { |d| d.annotated_id },
          events: {
            save: :update_on,
          }
        },
      ]

    cached_field :picture,
      start_as: proc { |pm| pm.lead_image },
      update_on: [] # Never changes

    cached_field :team_name,
      start_as: proc { |pm| pm.team.name },
      update_on: [] # Never changes

    cached_field :creator_name,
      start_as: proc { |pm| pm.get_creator_name },
      update_es: true,
      update_on: [
        {
          model: User,
          affected_ids: proc { |u|
            u.project_medias.where("channel->>'main'IN (?)", [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::BROWSER_EXTENSION].map(&:to_s)).map(&:id)
          },
          if: proc { |u| u.saved_change_to_name? },
          events: {
            update: :update_on,
          }
        },
      ]
  end
end
