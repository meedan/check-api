class TerminalStatusMailer < ApplicationMailer
	layout nil

	def notify(annotated, author, status)
    project = annotated.project
		team = project.team
		recipients = team.recipients(author, ['editor', 'owner'])
    created_at = annotated.created_at
    updated_at = annotated.updated_at
    image_path = annotated.media.type == 'UploadedImage' ? annotated.media.image_path : ''
		@info = {
      team: team.name,
      project: project.title,
      project_url: project.url,
      author: author.present? ? author.name : '',
      author_role: I18n.t("role_" + author.role(team).to_s),
      profile_image: author.profile_image,
      media_url: annotated.full_url,
      title: annotated.title,
      description: annotated.description,
      image_path: image_path,
      media_link: annotated.media.url,
      status: status,
      notes: annotated.get_versions_log_count,
      total_tasks: annotated.get_annotations('task').count,
      resolved_tasks: annotated.tasks_resolved_count,
      type: annotated.class.name.underscore,
      media_type: annotated.media.type.downcase,
      created_at: created_at.strftime("%B #{created_at.day.ordinalize} %I:%M %p"),
      updated_at: updated_at.strftime("%B #{updated_at.day.ordinalize} %I:%M %p")
    }
    subject = I18n.t('mails_notifications.media_status.subject', team: team.name, project: annotated.project.title, status: status)
    self.send_email_to_recipients(recipients, subject, 'terminal_status') unless recipients.empty?
	end

end
