require 'active_support/concern'

module AnnotationPrivate
  extend ActiveSupport::Concern

  private

  def set_type_and_event
    self.annotation_type ||= self.class_name.parameterize
    self.paper_trail_event = 'create' if self.versions.count === 0
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
    TeamBot.enqueue_event("#{event}_annotation_#{self.annotation_type}", team, self) unless team.blank?
    task = Task.where(id: self.id).last if self.annotation_type == 'task'
    TeamBot.enqueue_event("#{event}_annotation_task_#{self.data['type']}", team, task) unless team.blank? || task.nil?
  end

  def notify_bot_author
    if self.annotator.is_a?(BotUser)
      team_bot = self.annotator.team_bot
      team_bot.notify_about_annotation(self) unless team_bot.nil?
    end
  end
end
