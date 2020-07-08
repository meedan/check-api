module Workflow
  module Concerns
    module TeamConcern
      Team.class_eval do
        validate :custom_statuses_format, unless: proc { |t| t.settings.nil? || !t.changes.dig('settings') }

        CUSTOM_STATUSES_SCHEMA = {
          type: 'object',
          required: ['label', 'active', 'default', 'statuses'],
          properties: {
            label: { type: 'string', title: 'Label' },
            active: { type: 'string', title: 'Active' },
            default: { type: 'string', title: 'Default' },
            statuses: {
              type: 'array',
              title: 'Statuses',
              items: {
                type: 'object',
                title: 'Status',
                headerTemplate: '{{i1}} - {{self.id}}',
                required: ['id', 'style'],
                properties: {
                  id: { type: 'string', title: 'Identifier' },
                  style: {
                    type: 'object',
                    properties: {
                      color: { type: 'string', title: 'Color', format: 'color' },
                      backgroundColor: { type: 'string', title: 'Background color', format: 'color' },
                      borderColor: { type: 'string', title: 'Border color', format: 'color' }
                    }
                  },
                  locales: {
                    type: 'object',
                    patternProperties: {
                      '^[a-z]{2}$': {
                        type: 'object',
                        required: ['label', 'description'],
                        properties: {
                          label: { type: 'string' },
                          description: { type: 'string' }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        def self.custom_statuses_schema
          CUSTOM_STATUSES_SCHEMA
        end

        ::Workflow::Workflow.workflow_ids.each do |id|
          define_method id.pluralize do |type, obj = nil, items_count = false|
            statuses = self.send("get_#{type}_#{id.pluralize}") || ::Workflow::Workflow.core_options(type.camelize.constantize.new, id)
            statuses[:statuses].each{ |s| s[:can_change] = true } if !obj.nil? && type.to_s == 'media'
            if type.to_s == 'media' && items_count
              statuses[:statuses].each do |s|
                s[:items_count] = DynamicAnnotation::Field
                  .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id AND a.annotated_type = 'ProjectMedia' INNER JOIN project_medias pm ON pm.id = a.annotated_id")
                  .where(field_name: "#{id}_status", value: s[:id], 'pm.team_id' => self.id).count
              end
            end
            statuses
          end

          define_method "media_#{id.pluralize}=" do |statuses|
            send "set_#{id.pluralize}", 'media', statuses
          end

          define_method "media_#{id.pluralize}" do
            self.send "get_media_#{id.pluralize}"
          end

          define_method "source_#{id.pluralize}=" do |statuses|
            send "set_#{id.pluralize}", 'source', statuses
          end

          define_method "set_#{id.pluralize}" do |type, statuses|
            value = statuses.is_a?(String) ? JSON.parse(statuses) : statuses
            value[:statuses] = get_values_from_entry(value.with_indifferent_access[:statuses])
            self.send("set_#{type}_#{id.pluralize}", value)
          end
        end

        def get_media_statuses
          pm = ProjectMedia.new
          self.send("get_media_#{pm.default_project_media_status_type.pluralize}")
        end

        private

        def custom_statuses_format
          ::Workflow::Workflow.workflow_ids.each do |id|
            ['media', 'source'].each do |type|
              unless self.send("get_#{type}_#{id.pluralize}").nil?
                statuses = self.send("get_#{type}_#{id.pluralize}")
                errors.add(:settings, JSON::Validator.fully_validate(CUSTOM_STATUSES_SCHEMA, statuses)) if !JSON::Validator.validate(CUSTOM_STATUSES_SCHEMA, statuses)
              end
            end
          end
        end
      end # Team.class_eval
    end
  end
end
