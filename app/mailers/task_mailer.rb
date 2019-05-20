class TaskMailer < ApplicationMailer
	layout nil

	def notify(task, author)
    object = task.annotated
		project = object.project
		team = project.team
		recipients = team.recipients(author, ['owner'])
    item = object.title
    updated_at = task.updated_at
    @info = {
      author: author.name,
      profile_image: author.profile_image,
      project: object.project.title,
      project_url: object.project.url,
      role: I18n.t("role_" + author.role(object.project.team).to_s),
      team: team.name,
      title: task.label,
      description: task.description,
      status: task.status,
      response: task.first_response,
      media_title: object.title,
      media_url: object.full_url,
      updated_at: updated_at.strftime("%B #{updated_at.day.ordinalize} %I:%M %p"),
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.#{task.class.name.underscore}"), app: CONFIG['app_name']
      })
    }
		subject = I18n.t("mails_notifications.task_resolved.subject", team: @info[:team], project: @info[:project])
    self.send_email_to_recipients(recipients, subject, 'task_status') unless recipients.empty?
	end
end
