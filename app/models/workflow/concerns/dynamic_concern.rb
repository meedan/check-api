module Workflow
  module Concerns
    module DynamicConcern
      Dynamic.class_eval do
        before_validation :store_previous_status

        def status=(value)
          self.set_fields = { "#{self.annotation_type}_status" => value }.to_json
        end

        def status
          self&.get_field("#{self.annotation_type}_status")&.value
        end

        ::Workflow::Workflow.workflows.each do |workflow|
          id = workflow.id

          attr_accessor "previous_#{id}".to_sym

          define_method(id) do
            self.get_field("#{id}_status").to_s if self.annotation_type == id
          end
        end

        private

        def store_previous_status
          ::Workflow::Workflow.workflow_ids.each do |id|
            self.send("previous_#{id}=", self.send(id)) if self.annotation_type == id
          end
        end
      end # Dynamic.class_eval
    end
  end
end
