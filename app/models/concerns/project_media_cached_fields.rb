require 'active_support/concern'

module ProjectMediaCachedFields
  extend ActiveSupport::Concern

  # FIXME: Need to get this value from some API and update it periodically
  def virality
    0
  end

  module ClassMethods
    def metadata_update(field)
      {
        model: DynamicAnnotation::Field,
        if: proc { |f| f.field_name == 'metadata_value' },
        affected_ids: proc { |f|
          if f.annotation.annotated_type == 'ProjectMedia'
            [f.annotation.annotated_id]
          elsif ['Media', 'Link'].include?(f.annotation.annotated_type)
            ProjectMedia.where(media_id: f.annotation.annotated_id).map(&:id)
          end
        },
        events: {
          save: proc { |_pm, f| begin JSON.parse(f.value)[field] rescue nil end }
        }
      }
    end
  end

  included do
    cached_field :linked_items_count,
      start_as: 0,
      update_es: true,
      recalculate: proc { |pm| Relationship.where("source_id = ? OR target_id = ?", pm.id, pm.id).count },
      update_on: [
        {
          model: Relationship,
          affected_ids: proc { |r| [r.source_id, r.target_id] },
          events: {
            create: proc { |pm, _r| pm.linked_items_count + 1 },
            destroy: proc { |pm, _r| pm.linked_items_count - 1 }
          }
        }
      ]

    cached_field :requests_count,
      start_as: 0,
      update_es: true,
      recalculate: proc { |pm| Dynamic.where(annotation_type: 'smooch', annotated_id: pm.id).count },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' },
          affected_ids: proc { |d| [d.annotated_id] },
          events: {
            create: proc { |pm, _d| pm.requests_count + 1 }
          }
        }
      ]

    cached_field :demand,
      start_as: 0,
      recalculate: proc { |pm|
        n = 0
        pm.related_items_ids.collect{ |id| n += ProjectMedia.find(id).requests_count }
        n
      },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' },
          affected_ids: proc { |d| d.annotated.related_items_ids },
          events: {
            create: proc { |pm, _d| pm.demand + 1 }
          }
        },
        {
          model: Relationship,
          affected_ids: proc { |r| [r.source&.related_items_ids, r.target_id].flatten.reject{ |id| id.blank? }.uniq },
          events: {
            create: proc { |pm, r| pm.id == r.target_id ? r.source&.demand&.to_i : pm.demand + r.target&.demand&.to_i },
            destroy: proc { |pm, r| pm.id == r.target_id ? pm.requests_count : pm.demand - r.target&.requests_count&.to_i }
          }
        }
      ]

    cached_field :last_seen,
      start_as: proc { |pm| pm.created_at.to_i },
      update_es: true,
      recalculate: proc { |pm| (Dynamic.where(annotation_type: 'smooch', annotated_id: pm.related_items_ids).order('created_at DESC').first&.created_at || pm.reload.created_at).to_i },
      update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' },
          affected_ids: proc { |d| d.annotated&.related_items_ids.to_a },
          events: {
            create: proc { |_pm, d| d.created_at.to_i }
          }
        },
        {
          model: Relationship,
          affected_ids: proc { |r| r.source&.related_items_ids.to_a },
          events: {
            create: proc { |_pm, r| [r.source&.last_seen.to_i, r.target&.last_seen.to_i].max },
            destroy: :recalculate
          }
        }
      ]

    cached_field :description,
      recalculate: proc { |pm| pm.metadata.dig('description') || (pm.media.type == 'Claim' ? nil : pm.text) },
      update_on: [metadata_update('description')]

    cached_field :title,
      recalculate: proc { |pm| pm.metadata.dig('title') || pm.media.quote },
      update_on: [metadata_update('title')]

    cached_field :status,
      recalculate: proc { |pm| pm.last_verification_status },
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
  end
end
