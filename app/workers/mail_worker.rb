class MailWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'mail', retry: 0

  # Mailer class should implemnt `send_notification` or call your own method in perform

  def perform(mailer, options)
    mailer = mailer.constantize
    mailer.send('send_notification', options) if mailer.respond_to?('send_notification')
  end
end
