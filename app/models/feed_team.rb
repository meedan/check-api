class FeedTeam < ApplicationRecord
  check_settings

  belongs_to :team
  belongs_to :feed
  belongs_to :media_saved_search, -> { where(list_type: 'media') }, class_name: 'SavedSearch', optional: true
  belongs_to :article_saved_search, -> { where(list_type: 'article') }, class_name: 'SavedSearch', optional: true

  validates_presence_of :team_id, :feed_id
  validate :saved_search_belongs_to_feed_team
  validate :validate_saved_search_types

  after_destroy :delete_invitations

  def requests_filters=(filters)
    filters = filters.is_a?(String) ? JSON.parse(filters) : filters
    self.send(:set_requests_filters, filters)
  end

  def filters
    self.media_saved_search&.filters.to_h
  end

  def saved_search_was
    SavedSearch.find_by_id(self.media_saved_search_id_before_last_save)
  end

  private

  def saved_search_belongs_to_feed_team
    [media_saved_search, article_saved_search].each do |saved_search|
      next if saved_search.blank?

      if  self.team_id != saved_search.team_id
        errors.add("#{saved_search.list_type}_saved_search_id".to_sym, I18n.t(:"errors.messages.invalid_feed_saved_search_value"))
      end
    end
  end

  def validate_saved_search_types
    if media_saved_search.present? && media_saved_search.list_type != 'media'
      errors.add(:media_saved_search, I18n.t(:"errors.messages.invalid_feed_saved_search_value"))
    end

    if article_saved_search.present? && article_saved_search.list_type != 'article'
      errors.add(:article_saved_search, I18n.t(:"errors.messages.invalid_feed_saved_search_value"))
    end
  end

  def delete_invitations
    # Delete invitations to that feed when a user leaves a feed so they can be invited again in the future
    FeedInvitation.where(email: User.current.email, feed_id: self.feed_id).delete_all unless User.current.blank?
  end
end
