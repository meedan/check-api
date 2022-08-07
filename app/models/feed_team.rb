class FeedTeam < ApplicationRecord
  check_settings

  belongs_to :team
  belongs_to :feed
end
