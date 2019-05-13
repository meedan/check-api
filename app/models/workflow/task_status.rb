class Workflow::TaskStatus < Workflow::Base
  check_default_task_workflow

  check_workflow from: :any, to: :resolved, actions: :send_mail_notification

  def self.core_default_value
    'unresolved'
  end

  def self.core_active_value
    'unresolved'
  end

  def self.target
    Task
  end

  def self.notify_slack?
    false
  end

  Assignment.class_eval do
    after_create :reopen_task

    private

    def reopen_task
      if self.assigned_type == 'Annotation' && self.assigned.annotation_type == 'task'
        task = self.assigned.load
        task.status = 'unresolved'
        task.skip_notifications = true
        task.skip_check_ability = true
        task.save!
      end
    end
  end

  Dynamic.class_eval do
    after_destroy :reopen_task_after_destroying_answer

    private

    def reopen_task_after_destroying_answer
      if self.annotation_type =~ /^task_response/
        task = self.annotated
        task.status = 'unresolved'
        task.skip_notifications = true
        task.skip_check_ability = true
        task.save!(:validate => false)
      end
    end
  end

  DynamicAnnotation::Field.class_eval do
    protected

    def send_mail_notification
      if self.annotation.annotated_type == 'Task'
        TaskMailer.delay.notify(self.to_s.downcase, self.annotation.annotated, self.annotation.annotator)
      end
    end
  end
end
