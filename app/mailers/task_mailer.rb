class TaskMailer < ApplicationMailer
  layout nil

  def self.send_notification(options)
    options = YAML::load(options)
    task = options[:task]
    response = options[:response]
    answer = options[:answer].gsub(/\n/, '<br/>')
    status = options[:status]
    author = response.annotator
    object = task.annotated
    project = object.project
    team = project.team
    unless author.nil?
      author_name = author.name
      role = I18n.t("role_" + author.role(object.project.team).to_s)
      profile_image = author.profile_image
    end
    info = {
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
      created_at: response.created_at,
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.#{task.class.name.underscore}"), app: CONFIG['app_name']
      })
    }
    subject = I18n.t("mails_notifications.task_resolved.subject", team: team.name, project: project.title)

    recipients = team.recipients(author, ['owner'])
    # get assigner email
    assigner_email = nil
    a = Assignment.where(assigned_type: 'Annotation', assigned_id: task.id).last
    unless a.nil?
      assigner = a.assigner
      assigner_email = assigner.email unless assigner.nil?
    end
    recipients << assigner_email unless assigner_email.nil?
    recipients = recipients.uniq
    recipients = Bounce.remove_bounces(recipients)
    recipients.each do |recipient|
      notify(recipient, info, subject).deliver_now
    end
  end

  def notify(recipient, info, subject)
    self.set_template_var(info, recipient)
    mail(to: recipient, email_type: 'task_status', subject: subject)
  end

end
