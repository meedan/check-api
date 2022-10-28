class FeedTeam < ApplicationRecord
  check_settings

  belongs_to :team
  belongs_to :feed

  def requests_filters=(filters)
    filters = filters.is_a?(String) ? JSON.parse(filters) : filters
    self.send(:set_requests_filters, filters)
  end

  def sharing_enabled?
    self.shared
  end
end
