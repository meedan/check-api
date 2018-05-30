module Workflow
  module Concerns
    module ProjectMediaConcern
      ProjectMedia.class_eval do
        after_create :create_first_statuses

        def get_project_media_status
          self.last_status
        end

        def last_status
          self.send("last_#{self.default_media_status_type}")
        end

        def last_status_obj
          self.send("last_#{self.default_media_status_type}_obj")
        end

        def default_media_status_type
          CONFIG['default_workflow']
        end

        ::Workflow::Workflow.workflow_ids.each do |id|
          define_method "last_#{id}_obj" do
            self.get_annotations(id).first&.load
          end

          define_method "last_#{id}" do
            last = self.send("last_#{id}_obj")
            last.nil? ? ::Workflow::Workflow.options(self, id)[:default] : last.get_field("#{id}_status").value
          end
        end

        private

        def create_first_statuses
          ::Workflow::Workflow.workflow_ids.each do |id|
            type = DynamicAnnotation::AnnotationType.where(annotation_type: id).last
            unless type.nil?
              fields = {}
              type.schema.each do |fi|
                fields[fi.name.to_sym] = fi.name == "#{id}_status" ? ::Workflow::Workflow.options(self, id)[:default] : fi.default_value
              end
      
              next if self.project.team.is_being_copied

              user = User.current
              User.current = nil
              ts = Dynamic.new
              ts.skip_check_ability = true
              ts.skip_notifications = true
              ts.disable_es_callbacks = self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
              ts.annotation_type = id
              ts.annotated = self
              ts.annotator = self.user
              ts.set_fields = fields.to_json
              ts.created_at = self.created_at
              ts.save
              User.current = user
            end
          end
        end
      end # ProjectMedia.class_eval
    end
  end
end
