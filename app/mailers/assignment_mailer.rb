class AssignmentMailer < ApplicationMailer
  layout nil
    
  def notify(event, author, recipient, annotation_id)
    annotation = Annotation.find(annotation_id)
    project_media = annotation.annotated
    @event = event

    @project_media = project_media
    @info = {
      author: author.name
    }
    @info[:task] = annotation.load.label if annotation.annotation_type == 'task'
    @media_title = project_media.title

    Rails.logger.info "Sending e-mail from event #{event} to #{recipient}"
    mail(to: recipient, subject: I18n.t("mail_subject_#{event}".to_sym, team: project_media.project.team.name, project: project_media.project.title))
  end
end
