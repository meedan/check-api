class AssignmentMailer < ApplicationMailer
  layout nil
    
  def notify(event, author, recipient, project_media, annotation_id = nil)
    annotation = annotation_id.nil? ? nil : Annotation.find(annotation_id)
    @event = event

    @project_media = project_media
    @info = {
      author: author.name,
      project_media: project_media.title
    }
    @info[:task] = annotation.load.label if !annotation.nil? && annotation.annotation_type == 'task'

    Rails.logger.info "Sending e-mail from event #{event} to #{recipient}"
    mail(to: recipient, subject: I18n.t("mail_subject_#{event}").to_sym)
  end
end
