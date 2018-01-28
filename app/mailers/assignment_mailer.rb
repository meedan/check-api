class AssignmentMailer < ApplicationMailer
  layout nil
    
  def notify(event, author, recipient, project_media, task = nil)
    @event = event

    @project_media = project_media
    @info = {
      author: author.name,
      project_media: project_media.title
    }
    @info[:task] = task.label unless task.nil?

    Rails.logger.info "Sending e-mail from event #{event} to #{recipient}"
    mail(to: recipient, subject: I18n.t("mail_subject_#{event}").to_sym)
  end
end
