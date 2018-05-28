module Workflow
  module Concerns
    module TeamConcern
      Team.class_eval do
        validate :change_custom_media_statuses, if: proc { |t| t.get_limits_custom_statuses == true }
        validate :custom_statuses_format, unless: proc { |t| t.settings.nil? }

        ::Workflow::Workflow.workflow_ids.each do |id|
          define_method id.pluralize do |type, obj = nil|
            statuses = self.send("get_#{type}_#{id.pluralize}") || ::Workflow::Workflow.core_options(type.camelize.constantize.new, id)
            if !obj.nil? && type.to_s == 'media'
              completed = statuses[:statuses].select{ |s| s[:completed].to_i == 1 }.collect{ |s| s[:id] }
              statuses[:statuses].each{ |s| s[:can_change] = completed.include?(s[:id]) ? (obj.respond_to?(:is_completed?) && obj.is_completed?) : true }
            end
            statuses
          end

          define_method "media_#{id.pluralize}=" do |statuses|
            send "set_#{id.pluralize}", 'media', statuses
          end

          define_method "media_#{id.pluralize}" do
            statuses = self.send "get_media_#{id.pluralize}"
            unless statuses.blank?
              statuses['statuses'] = [] if statuses['statuses'].nil?
              statuses['statuses'].each{ |s| s['style'].delete_if{ |key, _value| key.to_sym != :color } if s['style'] }
            end
            statuses
          end

          define_method "source_#{id.pluralize}=" do |statuses|
            send "set_#{id.pluralize}", 'source', statuses
          end

          define_method "set_#{id.pluralize}" do |type, statuses|
            statuses = statuses.with_indifferent_access
            statuses[:statuses] = [] if statuses[:statuses].nil?

            if statuses[:statuses]
              statuses[:statuses] = get_values_from_entry(statuses[:statuses])
              statuses[:statuses].delete_if{ |s| s[:id].blank? && s[:label].blank? }
              statuses[:statuses].each{ |s| set_status_color(s) }
            end
            statuses.delete_if{ |_k, v| v.blank? }
            unless statuses.keys.map(&:to_sym) == [:label]
              self.send("set_#{type}_#{id.pluralize}", statuses)
            end
          end
        end
      
        def get_media_statuses
          pm = ProjectMedia.new
          self.send("get_media_#{pm.default_media_status_type.pluralize}")
        end

        protected

        def validate_statuses(statuses, id)
          statuses[:statuses].each do |status|
            errors.add(:statuses, I18n.t("invalid_statuses_format_for_custom_#{id}")) if status.keys.map(&:to_sym).sort != [:completed, :description, :id, :label, :style]
            errors.add(:statuses, I18n.t("invalid_id_or_label_for_custom_#{id}")) if status[:id].blank? || status[:label].blank?
          end
          [:default, :active].each do |status|
            errors.add(:statuses, I18n.t("blank_#{status}_status_for_custom_#{id}".to_sym)) if statuses[status].blank?
            errors.add(:statuses, I18n.t("invalid_#{status}_status_for_custom_#{id}".to_sym)) if !statuses[status].blank? && !statuses[:statuses].map { |s| s[:id] }.include?(statuses[status])
          end
        end

        def set_status_color(status)
          if status[:style] && status[:style].is_a?(Hash)
            color = status[:style][:color]
            status[:style][:backgroundColor] = color
            status[:style][:borderColor] = color
          end
        end

        private

        def custom_statuses_format
          ::Workflow::Workflow.workflow_ids.each do |id|
            ['media', 'source'].each do |type|
              unless self.send("get_#{type}_#{id.pluralize}").nil?
                statuses = self.send("get_#{type}_#{id.pluralize}")
                if !statuses.is_a?(Hash) || statuses[:label].blank? || !statuses[:statuses].is_a?(Array) || statuses[:statuses].size === 0
                  errors.add(:statuses, I18n.t("invalid_statuses_format_for_custom_#{id}"))
                else
                  validate_statuses(statuses, id)
                end
              end
            end
          end
        end

        def change_custom_media_statuses
          ::Workflow::Workflow.workflow_ids.each do |id|
            media_statuses = self.send("get_media_#{id.pluralize}")
            next if media_statuses.blank?
            list = ::Workflow::Workflow.validate_custom_statuses(self.id, media_statuses, id)
            unless list.blank?
              urls = list.collect{ |l| l[:url] }
              statuses = list.collect{ |l| l[:status] }.uniq
              errors.add(:base, I18n.t(:cant_change_custom_statuses, statuses: statuses, urls: urls))
            end
          end
        end
      end # Team.class_eval
    end
  end
end
