class FeedTeam < ApplicationRecord
  check_settings

  belongs_to :team
  belongs_to :feed

  def sharing_enabled?
    self.shared
  end
end
