class FeedInvitationMailer < ApplicationMailer
  layout nil

  def notify(record)
    @recipient = record.email
    @user = record.user
    @feed = record.feed
    @direction = ApplicationMailer.set_template_direction
    @due_at = record.created_at + CheckConfig.get('feed_invitation_due_to', 30).to_i.days
    Rails.logger.info "Sending a feed invitation e-mail to #{@recipient}"
    subject = I18n.t("mails_notifications.feed_invitation.subject", user: @user.name, feed: @feed.name)
    mail(to: @recipient, email_type: 'feed_invitation', subject: subject)
  end
end
