class RelevantResultsItem < ApplicationRecord
  belongs_to :article, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :team, optional: true

  before_validation :set_team_and_user, on: :create

  private

  def set_team_and_user
    self.team_id ||= Team.current&.id
    self.user_id ||= User.current&.id
  end
end
