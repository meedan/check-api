class BotResource < ActiveRecord::Base
  include Versioned

  validates_presence_of :uuid, :title, :content, :team_id

  belongs_to :team
end
