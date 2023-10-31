class FeedInvitation < ApplicationRecord
  enum state: { invited: 0, accepted: 1, rejected: 2 } # default: invited

  belongs_to :feed
  belongs_to :user

  before_validation :set_user, on: :create
  validates_presence_of :email, :feed, :user
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :send_feed_invitation_mail, if: proc { |_x| Team.current.present? }

  def accept!(team_id)
    feed_team = FeedTeam.new(feed_id: self.feed_id, team_id: team_id, shared: true)
    feed_team.skip_check_ability = true
    feed_team.save!
    self.update_column(:state, :accepted)
  end

  def reject!
    self.update_column(:state, :rejected)
  end

  private

  def set_user
    self.user ||= User.current
  end

  def send_feed_invitation_mail
    FeedInvitationMailer.delay.notify(self.id, Team.current.id)
  end
end
