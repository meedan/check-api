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

    { linked_items_count: 'confirmed', suggestions_count: 'suggested' }.each do |field_name, type|
      cached_field field_name,
        start_as: 0,
        update_es: true,
        recalculate: proc { |pm| Relationship.send(type).where(source_id: pm.id).count },
        update_on: [SIMILARITY_EVENT]
    end

    cached_field :related_count,
      start_as: 0,
      update_es: true,
      recalculate: proc { |pm| Relationship.default.where('source_id = ? OR target_id = ?', pm.id, pm.id).count },
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
      recalculate: proc { |pm| Dynamic.where(annotation_type: 'smooch', annotated_id: pm.id).count },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' && d.annotated_type == 'ProjectMedia' },
          affected_ids: proc { |d| [d.annotated_id] },
          events: {
            create: proc { |pm, _d| pm.requests_count + 1 },
            destroy: proc { |pm, _d| pm.requests_count - 1 }
          }
        }
      ]

    cached_field :demand,
      start_as: 0,
      update_es: true,
      recalculate: proc { |pm|
        n = 0
        pm.related_items_ids.collect{ |id| n += ProjectMedia.new(id: id).requests_count }
        n
      },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' && d.annotated_type == 'ProjectMedia' },
          affected_ids: proc { |d| d.annotated.related_items_ids },
          events: {
            create: proc { |pm, _d| pm.demand + 1 }
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
      recalculate: proc { |pm| (Dynamic.where(annotation_type: 'smooch', annotated_id: pm.related_items_ids).order('created_at DESC').first&.created_at || ProjectMedia.find(pm.id).created_at).to_i },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' && d.annotated_type == 'ProjectMedia' },
          affected_ids: proc { |d| d.annotated&.related_items_ids.to_a },
          events: {
            create: proc { |_pm, d| d.created_at.to_i }
          }
        },
        {
          model: Relationship,
          if: proc { |r| r.is_confirmed? },
          affected_ids: proc { |r| r.source&.related_items_ids.to_a },
          events: {
            save: proc { |_pm, r| [r.source&.last_seen.to_i, r.target&.last_seen.to_i].max },
            destroy: :recalculate
          }
        }
      ]

    cached_field :description,
      recalculate: proc { |pm| pm.get_description },
      update_on: title_or_description_update

    cached_field :title,
      update_es: true,
      es_field_name: :title_index,
      recalculate: proc { |pm| pm.get_title },
      update_on: title_or_description_update

    cached_field :status,
      recalculate: proc { |pm| pm.last_verification_status },
      update_es: proc { |pm, value| pm.status_ids.index(value) },
      es_field_name: :status_index,
      update_on: [
        {
          model: DynamicAnnotation::Field,
          if: proc { |f| f.field_name == 'verification_status_status' },
          affected_ids: proc { |f| [f.annotation&.annotated_id.to_i] },
          events: {
            save: proc { |_pm, f| f.value }
          }
        }
      ]

    [:share, :reaction, :comment].each do |metric|
      cached_field "#{metric}_count".to_sym,
        start_as: 0,
        update_es: true,
        recalculate: proc { |pm| begin JSON.parse(pm.get_annotations('metrics').last.load.get_field_value('metrics_data'))['facebook']["#{metric}_count"] rescue 0 end },
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
      update_es: proc { |_pm, value| ['unpublished', 'paused', 'published'].index(value) },
      recalculate: proc { |pm| Relationship.confirmed_parent(pm).get_dynamic_annotation('report_design')&.get_field_value('state') || 'unpublished' },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'report_design' },
          affected_ids: proc { |d| d.annotated.related_items_ids },
          events: {
            save: proc { |_pm, d| d.data.with_indifferent_access[:state] }
          }
        },
        SIMILARITY_EVENT
      ]

    cached_field :tags_as_sentence,
      start_as: proc { |_pm| '' },
      update_es: proc { |_pm, value| value.split(', ').size },
      recalculate: proc { |pm| pm.get_annotations('tag').map(&:load).map(&:tag_text).join(', ') },
      update_on: [
        {
          model: Tag,
          affected_ids: proc { |t| [t.annotated_id.to_i] },
          events: {
            save: proc { |pm, t| pm.tags_as_sentence.split(', ').concat([t.tag_text]).join(', ') },
            destroy: proc { |pm, t| pm.tags_as_sentence.split(', ').reject{ |tt| tt == t.tag_text }.join(', ') }
          }
        }
      ]

    cached_field :sources_as_sentence,
      start_as: proc { |_pm| '' },
      recalculate: proc { |pm| pm.get_project_media_sources },
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
      recalculate: proc { |pm| pm.published_at.to_i },
      update_on: [
        {
          model: Link,
          affected_ids: proc { |m| m.project_media_ids },
          events: {
            save: :recalculate
          }
        }
      ]

    cached_field :type_of_media,
      start_as: proc { |pm| pm.media.type },
      update_es: proc { |_pm, value| Media.types.index(value) },
      recalculate: proc { |pm| pm.media.type },
      update_on: [] # Should never change

    cached_field :added_as_similar_by_name,
      start_as: nil,
      update_es: false,
      recalculate: proc { |pm|
        user = Relationship.confirmed.where(target_id: pm.id).last&.user
        user && user == BotUser.alegre_user ? 'Check' : user&.name
      },
      update_on: [
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          events: {
            create: proc { |_pm, r| r.user && r.user == BotUser.alegre_user ? 'Check' : r.user&.name },
            destroy: proc { |_pm, _r| nil }
          }
        }
      ]

    cached_field :confirmed_as_similar_by_name,
      start_as: nil,
      update_es: false,
      recalculate: proc { |pm|
        r = Relationship.confirmed.where(target_id: pm.id).last
        r.nil? ? nil : User.find_by_id(r.confirmed_by.to_i)&.name
        # Could also get it from version:
        # Version.from_partition(pm.team_id).where(item_type: 'Relationship', item_id: r.id.to_s).where("object_changes LIKE '%suggested_sibling%confirmed_sibling%'").last&.user&.name
      },
      update_on: [
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          if: proc { |r| r.is_being_confirmed? },
          events: {
            save: proc { |_pm, _r| User.current&.name },
          }
        },
        {
          model: Relationship,
          affected_ids: proc { |r| [r.target_id] },
          events: {
            destroy: proc { |_pm, _r| nil }
          }
        }
      ]

    cached_field :folder,
      start_as: proc { |pm| pm.project&.title.to_s },
      recalculate: proc { |pm| pm.project&.title.to_s },
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
            save: proc { |_pm, p| p.title }
          }
        }
      ]

    cached_field :show_warning_cover,
      start_as: false,
      recalculate: proc { |pm| pm.get_dynamic_annotation('flag')&.get_field_value('show_cover') || false },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'flag' },
          affected_ids: proc { |d| d.annotated_id },
          events: {
            save: proc { |_pm, d| d.data.with_indifferent_access[:show_cover] }
          }
        },
      ]

    cached_field :picture,
      start_as: proc { |pm| pm.lead_image },
      update_es: false,
      recalculate: proc { |pm| pm.lead_image },
      update_on: [] # Never changes

    cached_field :team_name,
      start_as: proc { |pm| pm.team.name },
      update_es: false,
      recalculate: proc { |pm| pm.team.name },
      update_on: [] # Never changes

    cached_field :creator_name,
      start_as: proc { |pm| pm.get_creator_name },
      update_es: true,
      recalculate: proc { |pm| pm.get_creator_name },
      update_on: [
        {
          model: User,
          affected_ids: proc { |u|
            u.project_medias.where(channel: [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::BROWSER_EXTENSION]).map(&:id)
          },
          if: proc { |u| u.saved_change_to_name? },
          events: {
            update: proc { |_pm, u| u.name }
          }
        },
      ]
  end
end
