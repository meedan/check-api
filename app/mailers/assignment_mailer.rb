class AssignmentMailer < ApplicationMailer
  layout nil
    
  def notify(event, author, recipient, assigned)

    @event = event
    @info = {
      author: author ? author.name : ''
    }
    
    if assigned.is_a?(Annotation)
      annotation = assigned
      project_media = annotation.annotated
      @info[:task] = annotation.load.label if annotation.annotation_type == 'task'
      @title = project_media.title
      @url = project_media.full_url
      @team = project_media.project.team.name
      @project = project_media.project.title
    
    elsif assigned.is_a?(Project)
      @title = assigned.title
      @url = assigned.url
      @team = assigned.team.name
      @project = @title
    end

    Rails.logger.info "Sending e-mail from event #{event} to #{recipient}"
    mail(to: recipient, email_type: 'assignment', subject: I18n.t("mail_subject_#{event}".to_sym, team: @team, project: @project))
  end

  def ready(requestor_id, team, project, event, assignee)
    requestor = User.where(id: requestor_id).last
    return if requestor.nil? || assignee.nil?
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
