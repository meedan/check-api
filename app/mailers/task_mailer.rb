class TaskMailer < ApplicationMailer
	layout nil

	def notify(task, response, answer, status, notify_type = 'owner')
    author = response.annotator
    object = task.annotated
		project = object.project
		team = project.team
    created_at = response.created_at
    unless author.nil?
      author_name = author.name
      role = I18n.t("role_" + author.role(object.project.team).to_s)
      profile_image = author.profile_image
    end
    @info = {
      author: author_name,
      profile_image: profile_image,
      project: object.project.title,
      project_url: object.project.url,
      role: role,
      team: team.name,
      title: task.label,
      description: task.description,
      status: status,
      response: answer,
      media_title: object.title,
      media_url: object.full_url,
      created_at: created_at.strftime("%B #{created_at.day.ordinalize} %I:%M %p"),
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.#{task.class.name.underscore}"), app: CONFIG['app_name']
      })
    }
		subject = I18n.t("mails_notifications.task_resolved.subject", team: @info[:team], project: @info[:project])
    recipients = []
    if notify_type == 'owner'
      recipients = team.recipients(author, ['owner'])
    else
      a = Assignment.where(assigned_type: 'Annotation', assigned_id: task.id).last
      recipients = User.where(id: a.assigner_id).map(&:email) unless a.nil?
    end
    self.send_email_to_recipients(recipients, subject, 'task_status') unless recipients.empty?
	end
end
