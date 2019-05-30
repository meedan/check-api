class TaskMailer < ApplicationMailer
  layout nil

  def self.send_notificaton(task, response, answer, status)
    author = response.annotator
    object = task.annotated
    team = object.project.team
    recipients = team.recipients(author, ['owner'])
    assigner_email = get_assigner_email(task)
    recipients << assigner_email unless assigner_email.nil?
    recipients.uniq.each do |recipient|
      self.delay.notify(recipient, task, response, answer, status)
    end
  end

  def notify(recipient, task, response, answer, status)
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
    user = User.find_user_by_email(recipient)
    @info = {
      greeting: I18n.t("mails_notifications.greeting", username: user.name),
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
    subject = I18n.t("mails_notifications.task_resolved.subject", team: team.name, project: project.title)
    mail(to: recipient, email_type: 'task_status', subject: subject)
  end

  def get_assigner_email(task)
    email = nil
    a = Assignment.where(assigned_type: 'Annotation', assigned_id: task.id).last
    unless a.nil?
      assigner = a.assigner
      email = assigner.email unless assigner.nil?
    end
    email
  end
end
