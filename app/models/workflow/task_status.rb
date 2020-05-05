class Workflow::TaskStatus < Workflow::Base
  check_default_task_workflow

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

end
