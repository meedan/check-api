module Workflow
  module Concerns
    module TeamConcern
      Team.class_eval do
        validate :change_custom_media_statuses, if: proc { |t| t.custom_statuses_changed? }
        validate :custom_statuses_format, unless: proc { |t| t.settings.nil? || !t.changes.dig('settings') }

        CUSTOM_STATUSES_SCHEMA = {
          type: 'object',
          required: ['label', 'active', 'default', 'statuses'],
          properties: {
            label: { type: 'string' },
            active: { type: 'string' },
            default: { type: 'string' },
            statuses: {
              type: 'array',
              items: {
                type: 'object',
                required: ['id', 'style'],
                properties: {
                  id: { type: 'string' },
                  style: {
                    type: 'object',
                    properties: {
                      color: { type: 'string' },
                      backgroundColor: { type: 'string' },
                      borderColor: { type: 'string' }
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

        ::Workflow::Workflow.workflow_ids.each do |id|
          define_method id.pluralize do |type, obj = nil|
            statuses = self.send("get_#{type}_#{id.pluralize}") || ::Workflow::Workflow.core_options(type.camelize.constantize.new, id)
            statuses[:statuses].each{ |s| s[:can_change] = true } if !obj.nil? && type.to_s == 'media'
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
            self.send("set_#{type}_#{id.pluralize}", value)
          end
        end

        def get_media_statuses
          pm = ProjectMedia.new
          self.send("get_media_#{pm.default_project_media_status_type.pluralize}")
        end

        def custom_statuses_changed?
          changed = false
          ::Workflow::Workflow.workflow_ids.each do |id|
            statuses_were = self.settings_was.to_h.with_indifferent_access["media_#{id.pluralize}"]
            statuses_are = self.settings.to_h.with_indifferent_access["media_#{id.pluralize}"]
            changed = true if (statuses_were != statuses_are && (!statuses_were.blank? || !statuses_are.blank?))
          end
          changed
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

        def change_custom_media_statuses
          ::Workflow::Workflow.workflow_ids.each do |id|
            media_statuses = self.send("get_media_#{id.pluralize}")
            next if media_statuses.blank?
            validation = ::Workflow::Workflow.validate_custom_statuses(self.id, media_statuses, id)
            list = validation[:list]
            unless list.blank?
              urls = list.collect{ |l| l[:url] }.sort
              statuses = list.collect{ |l| l[:status] }.uniq
              others_amount = validation[:count] > 3 ? "(+ #{validation[:count] - 3})" : ''
              errors.add(:base, I18n.t(:cant_change_custom_statuses, statuses: statuses, urls: urls.join(", "), others_amount: others_amount ))
            end
          end
        end
      end # Team.class_eval
    end
  end
end
