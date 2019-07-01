require 'active_support/concern'

module AnnotationPrivate
  extend ActiveSupport::Concern

  private

  def set_type_and_event
    self.annotation_type ||= self.class_name.parameterize
    self.paper_trail_event = 'create' if self.id.blank?
  end

  def set_annotator
    self.annotator = User.current if self.annotator.nil? && !User.current.nil?
  end

  def notify_team_bots_create
    self.send :notify_team_bots, 'create'
  end

  def notify_team_bots_update
    self.send :notify_team_bots, 'update'
  end

  def notify_team_bots(event)
    team = self.get_team.first
    BotUser.enqueue_event("#{event}_annotation_#{self.annotation_type}", team, self) unless team.blank?
    task = Task.where(id: self.id).last if self.annotation_type == 'task'
    BotUser.enqueue_event("#{event}_annotation_task_#{self.data['type']}", team, task) unless team.blank? || task.blank?
  end

  def notify_bot_author
    if self.annotator.is_a?(BotUser)
      bot = self.annotator
      team = self.get_team.first
      BotUser.enqueue_event("update_annotation_own", team, self, bot) unless team.blank? || bot.blank?
    end
  end

  def remove_null_bytes
    self.data.each { |k, v| self.data[k] = v.gsub("\u0000", "\\u0000") if v.is_a?(String) }
  end
end
