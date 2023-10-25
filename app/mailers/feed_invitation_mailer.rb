class FeedInvitationMailer < ApplicationMailer
  layout nil

  def notify(record)
    @recipient = record.email
    @user = record.user
    @feed = record.feed
    @direction = ApplicationMailer.set_template_direction
    @due_at = record.created_at + CheckConfig.get('feed_invitation_due_to', 30).to_i.days
    subject = I18n.t("mails_notifications.feed_invitation.subject", user: @user.name, feed: @feed.name)
    attachments.inline['check_logo.png'] = File.read("#{Rails.root}/public/images/check.svg")
    @logo_url = attachments['check_logo.png'].url
    Rails.logger.info "Sending a feed invitation e-mail to #{@recipient}"
    mail(to: @recipient, email_type: 'feed_invitation', subject: subject)
  end
end
