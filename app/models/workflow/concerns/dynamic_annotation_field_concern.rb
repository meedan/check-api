module Workflow
  module Concerns
    module DynamicAnnotationFieldConcern
      DynamicAnnotation::Field.class_eval do
        attr_accessor :previous_status

        before_validation :normalize_workflow_status
        validate :workflow_status_is_valid
        validate :can_set_workflow_status, unless: proc { |x| x.skip_check_ability }

        def previous_value
          self.value_was.nil? ? self.value : self.value_was
        end

        def status
          self.value if ::Workflow::Workflow.is_field_name_a_workflow?(self.field_name)
        end

        def index_on_es
          self.update_elasticsearch_doc([self.annotation_type], { self.annotation_type => self.value }, self.annotation.annotated)
        end

        ::Workflow::Workflow.workflow_ids.each do |id|
          define_method "field_formatter_name_#{id}_status" do
            value = nil
            self.workflow_options[:statuses].each do |option|
              value = option[:label] if option[:id] == self.value
            end
            value || self.value.titleize
          end
        end

        def workflow_options
          if ::Workflow::Workflow.is_field_name_a_workflow?(self.field_name)
            annotated = self.annotation.annotated
            annotation_type = self.annotation.annotation_type
            ::Workflow::Workflow.options(annotated, annotation_type)
          end
        end

        def workflow_options_and_roles
          if ::Workflow::Workflow.is_field_name_a_workflow?(self.field_name)
            options_and_roles = {}
            self.workflow_options[:statuses].each do |option|
              options_and_roles[option[:id]] = option[:role]
            end
            options_and_roles.with_indifferent_access
          end
        end

        def workflow_options_from_key(key)
          statuses = self.workflow_options[:statuses]
          statuses.collect{ |s| s[:id] } if key == :any
        end

        protected

        def cant_change_status(user, options, from_status, to_status)
          !user.nil? && !options[to_status].blank? && !user.is_admin? && (!user.role?(options[to_status]) || !user.role?(options[from_status]))
        end

        def call_workflow_action(field_name, params)
          transition = (params.has_key?(:from) && params.has_key?(:to))
          if self.field_name == field_name && params[:if].call && self.valid_workflow_transition?(transition, params[:from], params[:to])
            self.send(params[:action])
          end
        end

        def valid_workflow_transition?(transition, from, to)
          !transition || (self.previous_status.to_s != self.value.to_s && self.workflow_transition_applies?(from, to))
        end

        def workflow_transition_applies?(from, to)
          from = self.workflow_options_from_key(from)
          to = self.workflow_options_from_key(to)
          to.include?(self.value.to_s) && from.include?(self.previous_status.to_s)
        end

        private

        def normalize_workflow_status
          if ::Workflow::Workflow.is_field_name_a_workflow?(self.field_name)
            self.value = self.value.tr(' ', '_').downcase unless self.value.blank?
          end
        end

        def workflow_status_is_valid
          if ::Workflow::Workflow.is_field_name_a_workflow?(self.field_name)
            options = self.workflow_options_and_roles
            value = self.value.to_sym

            errors.add(:base, I18n.t(:workflow_status_not_valid)) unless options.keys.map(&:to_sym).include?(value)
          end
        end

        def can_set_workflow_status
          if ::Workflow::Workflow.is_field_name_a_workflow?(self.field_name)
            options = self.workflow_options_and_roles
            value = self.value.to_sym
            old_value = self.previous_value.to_sym
            self.previous_status = old_value
            user = User.current

            if self.cant_change_status(user, options, old_value, value)
              errors.add(:base, I18n.t(:workflow_status_permission_error))
            end
          end
        end
      end # DynamicAnnotation::Field.class_eval
    end
  end
end
