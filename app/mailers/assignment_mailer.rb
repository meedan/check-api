class AssignmentMailer < ApplicationMailer
  layout nil
    
  def notify(event, author, recipient, assigned)
    return unless should_notify?(recipient, assigned)

    @event = event
    
    if assigned.is_a?(Annotation)
      annotation = assigned
      project_media = annotation.annotated
      url = project_media.full_url
      title, media_title = project_media.title
      description = project_media.description
      project = project_media.project
      team = project.team
      media_title = project_media.title
      if annotation.annotation_type == 'task'
        task = annotation.load
        title = task.label
        description = task.description
      end
      # add more info related to media 
      image_path = project_media.media.type == 'UploadedImage' ? project_media.media.image_path : ''
      media_link = project_media.media.url
      updated_at = project_media.updated_at.strftime("%B #{project_media.updated_at.day.ordinalize} %I:%M %p")
      total_tasks = project_media.get_annotations('task').count
      resolved_tasks =  project_media.tasks_resolved_count
    elsif assigned.is_a?(Project)
      project = assigned
      title = project.title
      url = project.url
      team = project.team
      description = project.description
    end
    created_at = assigned.created_at
    unless author.nil?
      author_name = author.name
      author_id = author.id
      role = I18n.t("role_" + author.role(team).to_s)
      profile_image = author.profile_image
    end
    # map verification_status and translation_status to one event called "item"
    event_key = event.gsub("verification_status", "media").gsub("translation_status", "media")
    model = event_key.partition('_').last
    info = {
      event_key: event_key,
      event_type: event.partition('_').first,
      model: model,
      author: author_name,
      author_id: author_id,
      team: team.name,
      project: project.title,
      title: title,
      media_title: media_title,
      url: url,
      profile_image: profile_image,
      role: role,
      created_at: created_at.strftime("%B #{created_at.day.ordinalize} %I:%M %p"),
      image_path: image_path,
      media_link: media_link,
      updated_at: updated_at,
      total_tasks: total_tasks,
      resolved_tasks: resolved_tasks,
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.#{model}"), app: CONFIG['app_name']
      }),
      project_url: project.url,
      description: description,
    }

    Rails.logger.info "Sending e-mail from event #{event} to #{recipient}"
    subject = I18n.t("mails_notifications.assignment.#{info[:event_key]}_subject", team: info[:team], project: info[:project])
    self.set_template_var(info, recipient)
    mail(to: recipient, email_type: 'assignment', subject: subject)
  end

  def should_notify?(recipient, assigned)
    !recipient.blank? && assigned.class.exists?(assigned.id)
  end

  def ready(requestor_id, team, project, event, assignee)
    requestor = User.where(id: requestor_id).last
    return if requestor.nil? || assignee.nil? || requestor.email.blank?
    @event = event
    @username = requestor.name
    @project_title = project.title
    @project_url = project.url
    @assignee = assignee.name
    @app_name = CONFIG['app_name']
    Rails.logger.info "Sending e-mail to #{requestor.email} because the assignments are ready"
    mail(to: requestor.email, email_type: 'assignment', subject: I18n.t(:mail_subject_assignments_ready, team: team&.name, project: project&.title))
  end
end
