require 'active_support/concern'

module TeamValidations
  extend ActiveSupport::Concern

  included do
    validates_presence_of :name
    validates_presence_of :slug
    validates_format_of :slug, with: /\A[[:alnum:]-]+\z/, message: :slug_format
    validates :slug, length: { in: 4..63 }
    validates :slug, uniqueness: true
    validate :slug_is_not_reserved
    validates :logo, size: true
    validate :slack_webhook_format
    validate :slack_channel_format
    validate :custom_media_statuses_format, unless: proc { |p| p.settings.nil? || p.get_media_verification_statuses.nil? }
    validate :custom_source_statuses_format, unless: proc { |p| p.settings.nil? || p.get_source_verification_statuses.nil? }
    validate :checklist_format
    validate :change_custom_media_statuses, if: proc {|t| t.get_limits_custom_statuses == true}
  end
end
