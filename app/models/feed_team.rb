class FeedTeam < ApplicationRecord
  check_settings

  belongs_to :team
  belongs_to :feed
  belongs_to :saved_search, optional: true

  validates_presence_of :team_id, :feed_id
  validate :saved_search_belongs_to_feed_team

  def requests_filters=(filters)
    filters = filters.is_a?(String) ? JSON.parse(filters) : filters
    self.send(:set_requests_filters, filters)
  end

  def sharing_enabled?
    self.shared
  end

  def filters
    self.saved_search&.filters.to_h
  end

  private

  def saved_search_belongs_to_feed_team
    unless saved_search_id.blank?
      errors.add(:saved_search_id, I18n.t(:"errors.messages.invalid_feed_saved_search_value")) if self.team_id != self.saved_search.team_id
    end
  end
end
