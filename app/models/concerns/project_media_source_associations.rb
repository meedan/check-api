require 'active_support/concern'

module ProjectMediaSourceAssociations
  extend ActiveSupport::Concern

  def create_auto_tasks(project_id = nil, tasks = [])
    team = self.team
    return if team.nil? || team.is_being_copied
    self.set_tasks_responses ||= {}
    if tasks.blank?
      tasks = self.team.auto_tasks(project_id, false, self.class.name)
    end
    created = []
    tasks.each do |task|
      t = Task.new
      t.label = task.label
      t.type = task.task_type
      t.description = task.description
      t.team_task_id = task.id
      t.json_schema = task.json_schema
      t.options = task.options unless task.options.blank?
      t.annotator = User.current
      t.annotated = self
      t.order = task.order
      t.fieldset = task.fieldset
      t.skip_check_ability = true
      t.skip_notifications = true
      t.save!
      created << t
      # set auto-response
      if self.class.name == 'ProjectMedia'
        self.set_jsonld_response(task) unless task.mapping.blank?
      end
    end
    self.respond_to_auto_tasks(created)
  end

  def ordered_tasks(fieldset, associated_type = nil)
    associated_type ||= 'ProjectMedia'
    Task.where(annotation_type: 'task', annotated_type: associated_type, annotated_id: self.id).select{ |t| t.fieldset == fieldset }.sort_by{ |t| t.order || t.id || 0 }.to_a
  end

  def task_value(team_task_id, force = false)
    key = "#{self.class.name.underscore}:task_value:#{self.id}:#{team_task_id}"
    Rails.cache.fetch(key, force: force) do
      task = Task.where(annotation_type: 'task', annotated_type: self.class.name, annotated_id: self.id).select{ |t| t.team_task_id == team_task_id }.last
      task.nil? ? nil : task.first_response
    end
  end

  protected

  def respond_to_auto_tasks(tasks)
    # set_tasks_responses = { task_slug (string) => response (string) }
    responses = self.set_tasks_responses.to_h
    tasks.each do |task|
      if responses.has_key?(task.slug)
        task = Task.find(task.id)
        type = "task_response_#{task.type}"
        fields = {
          "response_#{task.type}" => responses[task.slug]
        }
        task.response = { annotation_type: type, set_fields: fields.to_json }.to_json
        task.save!
      end
    end
  end
end
