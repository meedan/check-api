class FeedTeam < ApplicationRecord
  check_settings

  belongs_to :team
  belongs_to :feed
  belongs_to :media_saved_search, class_name: 'SavedSearch', optional: true

  validates_presence_of :team_id, :feed_id
  validate :saved_search_belongs_to_feed_team

  after_destroy :delete_invitations

  def requests_filters=(filters)
    filters = filters.is_a?(String) ? JSON.parse(filters) : filters
    self.send(:set_requests_filters, filters)
  end

  def filters
    self.saved_search&.filters.to_h
  end

  def saved_search_was
    SavedSearch.find_by_id(self.saved_search_id_before_last_save)
  end

  private

  def saved_search_belongs_to_feed_team
    unless saved_search_id.blank?
      errors.add(:saved_search_id, I18n.t(:"errors.messages.invalid_feed_saved_search_value")) if self.team_id != self.saved_search.team_id
    end
  end

  def delete_invitations
    # Delete invitations to that feed when a user leaves a feed so they can be invited again in the future
    FeedInvitation.where(email: User.current.email, feed_id: self.feed_id).delete_all unless User.current.blank?
  end
end
