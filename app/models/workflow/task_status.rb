class Workflow::TaskStatus < Workflow::Base
  check_default_task_workflow

  check_workflow on: :commit, actions: :send_mail_notification, events: [:create, :update]

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
      if self.annotation.annotated_type == 'Task' && self.status == 'resolved'
        task = self.annotation.annotated
        unless task.first_response_obj.nil?
          # Notify team owner and assigner.
          TaskMailer.delay.notify(task, task.first_response_obj, task.first_response, self.to_s)
          TaskMailer.delay.notify(task, task.first_response_obj, task.first_response, self.to_s, 'assigner')
        end
      end
    end
  end

end
