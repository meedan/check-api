module Workflow
  module Concerns
    module TeamConcern
      Team.class_eval do
        validate :change_custom_media_statuses, if: proc { |t| t.custom_statuses_changed? }
        validate :custom_statuses_format, unless: proc { |t| t.settings.nil? || !t.changes.dig('settings') }

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

        def final_media_statuses
          pm = ProjectMedia.new(project: Project.new(team_id: self.id), team: self, team_id: self.id)
          statuses = ::Workflow::Workflow.options(pm, pm.default_project_media_status_type)[:statuses]
          statuses.select{ |st| st.with_indifferent_access['completed'].to_i == 1 }.collect{ |st| st.with_indifferent_access['id'] }
        end

        protected

        def validate_statuses(statuses, id)
          statuses[:statuses].each do |status|
            errors.add(:statuses, I18n.t("invalid_statuses_format_for_custom_#{id}")) if status.keys.map(&:to_sym).sort != [:completed, :description, :id, :label, :style]
            errors.add(:statuses, I18n.t("invalid_label_for_custom_#{id}")) if status[:label].blank?
            self.validate_status_id(status[:id], id)
          end
          [:default, :active].each do |status|
            errors.add(:statuses, I18n.t("blank_#{status}_status_for_custom_#{id}".to_sym)) if statuses[status].blank?
            errors.add(:statuses, I18n.t("invalid_#{status}_status_for_custom_#{id}".to_sym)) if !statuses[:statuses].map{ |s| s[:id] }.include?(statuses[status]) && !statuses[status].blank?
          end
        end

        def validate_status_id(status_id, id)
          errors.add(:statuses, I18n.t("invalid_id_for_custom_#{id}")) if status_id.blank? || status_id.match(/^[a-z0-9_\-]+$/).nil?
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
              urls = list.collect{ |l| l[:url] }.sort
              statuses = list.collect{ |l| l[:status] }.uniq
              others_amount = urls.size > 5 ? "(+ #{urls.size - 5})" : ''
              errors.add(:base, I18n.t(:cant_change_custom_statuses, statuses: statuses, urls: urls.first(5).join(", "), others_amount: others_amount ))
            end
          end
        end
      end # Team.class_eval
    end
  end
end
