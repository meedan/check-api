class Feed < ApplicationRecord
  check_settings

  has_many :feed_teams
  has_many :teams, through: :feed_teams
end
