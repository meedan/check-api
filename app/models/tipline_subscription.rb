class TiplineSubscription < ApplicationRecord
  has_paper_trail on: [:destroy], save_changes: true, ignore: [:updated_at, :created_at], versions: { class_name: 'Version' }

  validates_presence_of :uid, :language, :team_id, :platform

  belongs_to :team
end
