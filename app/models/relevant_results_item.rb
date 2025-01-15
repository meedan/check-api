class RelevantResultsItem < ApplicationRecord
  belongs_to :article, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :team, optional: true

  before_validation :set_team_and_user, on: :create
  validates_presence_of :team, :user, :query_media_parent_id
  validates :user_action, included: { values: %w(relevant_articles article_search) }

  private

  def set_team_and_user
    self.team_id ||= Team.current&.id
    self.user_id ||= User.current&.id
  end
end
