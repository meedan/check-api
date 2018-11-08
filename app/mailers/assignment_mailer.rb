class AssignmentMailer < ApplicationMailer
  layout nil
    
  def notify(event, author, recipient, assigned)

    @event = event
    @info = {
      author: author.name
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
end
