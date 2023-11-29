require_relative '../test_helper'

class FeedInvitationTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test 'should create feed invitation' do
    assert_difference 'FeedInvitation.count' do
      create_feed_invitation
    end
  end

  test 'should not create feed invitation without feed' do
    assert_no_difference 'FeedInvitation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_feed_invitation feed: nil
      end
    end
  end

  test 'should not create feed invitation without user' do
    assert_no_difference 'FeedInvitation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_feed_invitation user: nil
      end
    end
  end

  test 'should not create feed invitation without email' do
    assert_no_difference 'FeedInvitation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_feed_invitation email: nil
      end
    end
  end

  test 'should not create feed invitation with invalid email' do
    assert_no_difference 'FeedInvitation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_feed_invitation email: random_string
      end
    end
  end

  test 'should belong to feed and user' do
    fi = create_feed_invitation
    assert_kind_of Feed, fi.feed
    assert_kind_of User, fi.user
  end

  test 'should accept and reject invitation' do
    f = create_feed
    t = create_team
    fi = create_feed_invitation feed: f
    assert_equal 'invited', fi.reload.state
    assert_difference "FeedTeam.where(feed_id: #{f.id}, team_id: #{t.id}).count" do
      fi.accept!(t.id)
    end
    assert_equal 'accepted', fi.reload.state
    fi.reject!
    assert_nil FeedInvitation.find_by_id(fi.id)
  end

  test "should send email after create feed invitation" do
    u = create_user
    f = create_feed
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Extensions::DelayedMailer.clear
    Sidekiq::Testing.fake! do
      FeedInvitation.create!({ email: random_email, feed: f, user: u, state: :invited })
      assert_equal 1, Sidekiq::Extensions::DelayedMailer.jobs.size
    end
    Team.unstub(:current)
  end
end
