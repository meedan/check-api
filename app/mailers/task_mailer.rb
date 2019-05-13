class TaskMailer < ApplicationMailer
	layout nil

	def notify(type, annotated, author)
		project = annotated.project
		team = project.team
		recipients = team.recipients(author, ['owner'])
		@user = author
		subject = I18n.t("mail_task.#{type}_subject", team: team.name, project: project.title)
    self.send_email_to_recipients(recipients, subject, 'task_status') unless recipients.empty?
	end
end
