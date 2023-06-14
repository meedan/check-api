class FeedTeam < ApplicationRecord
  check_settings

  belongs_to :team
  belongs_to :feed
  belongs_to :saved_search, optional: true

  def requests_filters=(filters)
    filters = filters.is_a?(String) ? JSON.parse(filters) : filters
    self.send(:set_requests_filters, filters)
  end

  def sharing_enabled?
    self.shared
  end

  def filters
    self.saved_search.filters
  end
end
