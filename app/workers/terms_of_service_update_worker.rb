class TermsOfServiceUpdateWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'terms_mailer', retry: 0

  def perform
    last_updated = Time.at(User.terms_last_updated_at)
    updated_time = Time.now
    User.where(is_active: true).where('email IS NOT NULL').where('last_received_terms_email_at < ?', last_updated).find_each do |u|
      UpdatedTermsMailer.delay({ retry: 0, queue: 'terms_mailer' }).notify(u.email, u.name)
      u.update_columns(last_received_terms_email_at: updated_time)
    end
  end
end
