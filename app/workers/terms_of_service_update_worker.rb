class TermsOfServiceUpdateWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'terms_mailer', retry: 0

  def perform
    if Rails.cache.read('enable_terms_last_updated_at_notification')
      last_updated = Time.at(User.terms_last_updated_at)
      updated_time = Time.now
      # Based on our AWS SES account (Maximum send rate: 200 emails per second) I set a batch size 200 and do a sleep 1
      User.where(is_active: true).where('email IS NOT NULL')
      .where('last_received_terms_email_at < ?', last_updated)
      .find_in_batches(:batch_size => 200) do |users|
        users.each do |u|
          UpdatedTermsMailer.delay({ retry: 1, queue: 'terms_mailer' }).notify(u.email, u.name)
          u.update_columns(last_received_terms_email_at: updated_time)
        end
        sleep 2
      end
    end
  end
end
