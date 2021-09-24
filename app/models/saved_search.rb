class SavedSearch < ApplicationRecord
  attr_accessor :is_being_copied

  validates_presence_of :title, :team_id
  validates :title, uniqueness: { scope: :team_id }, unless: proc { |ss| ss.is_being_copied }

  belongs_to :team, optional: true
end
