class TermsOfServiceUpdateWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'terms_mailer', retry: 0

  def perform
    last_updated = User.terms_last_updated_at
    User.where('last_received_terms_email_at < ?', last_updated).find_each do |u|
      UpdatedTermsMailer.delay({ retry: 0, queue: 'terms_mailer' }).notify(u.email, u.name)
    end
  end
end
