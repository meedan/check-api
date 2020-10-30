class BotResource < ActiveRecord::Base
  include Versioned

  validates_presence_of :uuid, :title, :team_id

  belongs_to :team
end
