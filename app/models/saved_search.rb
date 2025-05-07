class SavedSearch < ApplicationRecord
  attr_accessor :is_being_copied

  enum list_type: { media: 0, article: 1 }

  validates_presence_of :title, :team_id
  validates :title, uniqueness: { scope: [:team_id, :list_type] }, unless: proc { |ss| ss.is_being_copied }

  belongs_to :team, optional: true
  has_many :feeds, dependent: :nullify
  has_many :feed_teams, dependent: :nullify

  def items_count
    if self.list_type == 'article'
      filters = self.filters || {}
      self.team.team_articles_count(filters.with_indifferent_access)
    elsif self.list_type == 'media'
      CheckSearch.new(self.filters.to_json, nil, self.team_id).number_of_results
    end
  end
end
