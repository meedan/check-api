class RegistrationMailer < ApplicationMailer
  layout nil

  def welcome_email(user)
    @user = user
    @url = CONFIG['checkdesk_client']
    mail(to: @user.email, subject: 'New account for you on Check')
  end
end
