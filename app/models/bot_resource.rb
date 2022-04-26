class BotResource < ApplicationRecord
  # include Versioned

  validates_presence_of :uuid, :title, :team_id

  belongs_to :team, optional: true
end
