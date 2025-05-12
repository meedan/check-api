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
      filters = begin self.filters.with_indifferent_access rescue {} end
      # Add filters with same name in team articles filters i.e map channels to channel and users to user_ids
      filters[:channel] = filters[:channels] unless filters[:channels].blank?
      filters[:user_ids] = filters[:users] unless filters[:users].blank?
      self.team.team_articles_count(filters.with_indifferent_access)
    elsif self.list_type == 'media'
      CheckSearch.new(self.filters.to_json, nil, self.team_id).number_of_results
    end
  end
end
