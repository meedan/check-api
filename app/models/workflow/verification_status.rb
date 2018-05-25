class Workflow::VerificationStatus < Workflow::Base
  
  check_workflow_default if CONFIG['app_name'] == 'Check'
  
  check_workflow from: :any, to: :terminal, actions: :send_terminal_notification_if_can_complete_media
  check_workflow on: :commit, actions: :index_on_es, events: [:create, :update]
  
  def self.core_default_value
    'undetermined'
  end

  def self.core_active_value
    'in_progress'
  end
     
  [Task, Comment, Tag, Flag, Dynamic].each do |annotation_class|
    annotation_class.class_eval do
      attr_accessor :disable_update_status
      
      after_create :update_annotated_status, if: proc { |obj| obj.annotated_type == 'ProjectMedia' && !obj.is_being_copied }

      private

      def update_annotated_status
        return if self.disable_update_status
        if self.class.name != 'Dynamic' || self.annotation_type =~ /^task_response/
          self.annotated.move_media_to_active_status unless self.annotated.nil?
        end
      end
    end
  end

  Task.class_eval do
    after_create :back_status_to_active, unless: proc { |task| task.is_being_copied }

    private

    def back_status_to_active
      if self.required == true && self.annotated_type == 'ProjectMedia'
        annotated = self.annotated
        vs = annotated.get_annotations('verification_status').last
        if !vs.nil? && !vs.locked
          vs = vs.load
          completed = ::Workflow::Workflow.options(self.annotated, 'verification_status')[:statuses].select{ |s| s[:completed].to_i == 1 }.collect{ |s| s[:id] }
          annotated.set_active_status(vs) if completed.include?(vs.get_field('verification_status_status').value) 
        end
      end
    end
  end

  ProjectMedia.class_eval do
    def move_media_to_active_status
      return unless CONFIG['app_name'] == 'Check'
      s = self.get_annotations('verification_status').last
      s = s.load unless s.nil?
      self.set_active_status(s) if !s.nil? && s.get_field('verification_status_status').value == ::Workflow::Workflow.options(self, 'verification_status')[:default] && !s.locked
    end

    def set_active_status(s)
      active = ::Workflow::Workflow.options(self, 'verification_status')[:active]
      f = s.get_field('verification_status_status')
      unless active.nil?
        f.value = active
        f.skip_check_ability = true
        f.save!
      end
    end
  end

  DynamicAnnotation::Field.class_eval do
    protected

    def send_terminal_notification_if_can_complete_media
      annotation = self.annotation
      if annotation.annotated_type == 'ProjectMedia'
        if annotation.annotated.is_completed?
          return if annotation.is_being_copied
          TerminalStatusMailer.delay.notify(annotation.annotated, annotation.annotator, self.value.to_s)
        else
          errors.add(:base, I18n.t(:must_resolve_required_tasks_first))
          raise ActiveRecord::RecordInvalid.new(self)
        end
      end
    end
  end
end
