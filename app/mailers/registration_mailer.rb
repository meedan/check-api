class RegistrationMailer < ApplicationMailer
  layout nil

  def welcome_email(user)
    @user = user
    @url = CONFIG['checkdesk_base_url']
    mail(to: @user.email, subject: 'New account for you on Checkdesk')
  end
end
