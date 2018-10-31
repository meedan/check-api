module Workflow
  module Concerns
    module TargetConcern
      ::Workflow::Workflow.workflows.each do |workflow|

        workflow_id = workflow.id # translation_status, verification_status, task_status, etc.

        target_id = workflow.target.name.underscore # project_media, task, etc.

        workflow.target.class_eval do
          after_create "create_first_#{workflow_id}"

          define_method "get_#{target_id}_status" do
            self.last_status
          end

          define_method "default_#{target_id}_status_type" do
            CONFIG["default_#{target_id}_workflow"]
          end

          define_method "last_#{workflow_id}_obj" do
            a = Annotation.where(annotation_type: workflow_id, annotated_type: self.class.name, annotated_id: self.id).last
            a.nil? ? nil : (a.load || a)
          end

          define_method "last_#{workflow_id}" do
            last = self.send("last_#{workflow_id}_obj")
            last.nil? ? ::Workflow::Workflow.options(self, workflow_id)[:default] : last.get_field("#{workflow_id}_status").value
          end

          define_method "last_#{workflow_id}_label" do
            last = self.send("last_#{workflow_id}_obj")
            return '' if last.nil?
            label = ''
            ::Workflow::Workflow.options(self, workflow_id).with_indifferent_access['statuses'].each do |status|
              label = status['label'] if status['id'] == self.send("last_#{workflow_id}")
            end
            label
          end

          define_method :last_status do
            default = self.send("default_#{target_id}_status_type")
            self.send("last_#{default}")
          end

          define_method :last_status_obj do
            default = self.send("default_#{target_id}_status_type")
            self.send("last_#{default}_obj")
          end

          private

          define_method "create_first_#{workflow_id}" do
            type = DynamicAnnotation::AnnotationType.where(annotation_type: workflow_id).last
            unless type.nil?
              fields = {}
              type.schema.each do |fi|
                fields[fi.name.to_sym] = fi.name == "#{workflow_id}_status" ? ::Workflow::Workflow.options(self, workflow_id)[:default] : fi.default_value
              end
      
              next if self.project.team.is_being_copied

              user = User.current
              User.current = nil
              ts = Dynamic.new
              ts.skip_check_ability = true
              ts.skip_notifications = true
              ts.disable_es_callbacks = self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
              ts.annotation_type = workflow_id
              ts.annotated = self
              ts.annotator = self.user
              ts.set_fields = fields.to_json
              ts.created_at = self.created_at
              ts.save
              User.current = user
            end
          end
        end # workflow.target.class_eval
      end
    end
  end
end
