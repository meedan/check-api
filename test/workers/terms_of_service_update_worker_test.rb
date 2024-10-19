require_relative '../test_helper'

class TermsOfServiceUpdateWorkerTest < ActiveSupport::TestCase
  test "should notify users based on last term update" do
    User.stubs(:terms_last_updated_at).returns(Time.now.to_i)
    terms_update = Time.now - 1.day
    u = create_user
    u.last_received_terms_email_at = terms_update
    u.save!
    last_received_terms_email_at = u.reload.last_received_terms_email_at
    TermsOfServiceUpdateWorker.new.perform
    assert_equal last_received_terms_email_at, u.reload.last_received_terms_email_at
    Rails.cache.write('enable_terms_last_updated_at_notification', true)
    TermsOfServiceUpdateWorker.new.perform
    last_term_update = u.reload.last_received_terms_email_at
    assert last_term_update > terms_update
    TermsOfServiceUpdateWorker.new.perform
    assert_equal last_term_update, u.reload.last_received_terms_email_at
  end

  test "should notify users in background" do
    Rails.cache.write('enable_terms_last_updated_at_notification', true)
    User.stubs(:terms_last_updated_at).returns(Time.now.to_i)
    terms_update = Time.now - 1.day
    u = create_user
    u.last_received_terms_email_at = terms_update
    u.save!
    u2 = create_user
    u2.last_received_terms_email_at = terms_update
    u2.save!
    Sidekiq::Testing.fake! do
      TermsOfServiceUpdateWorker.clear
      TermsOfServiceUpdateWorker.perform_in(1.second)
      assert 3, TermsOfServiceUpdateWorker.jobs.size
    end
    Sidekiq::Worker.drain_all
    assert u.reload.last_received_terms_email_at > terms_update
    assert u2.reload.last_received_terms_email_at > terms_update
    assert 0, TermsOfServiceUpdateWorker.jobs.size
  end
end
