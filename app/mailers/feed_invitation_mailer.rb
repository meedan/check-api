class FeedInvitationMailer < ApplicationMailer
	layout nil

	def notify(record)
		@recipient = record.email
		@user = record.user
		@feed = record.feed
		@title = 'Sawy title Sawy'
		@direction = ApplicationMailer.set_template_direction
		Rails.logger.info "Sending a feed invitation e-mail from to #{@recipient}"
    subject = I18n.t("mails_notifications.feed_invitation.subject", user: @user.name, feed: @feed.name)
    mail(to: @recipient, email_type: 'feed_invitation', subject: subject)
	end
end
