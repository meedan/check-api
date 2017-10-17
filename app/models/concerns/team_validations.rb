require 'active_support/concern'

module TeamValidations
  extend ActiveSupport::Concern
  
  included do
    validates_presence_of :name
    validates_presence_of :slug
    validates_format_of :slug, with: /\A[[:alnum:]-]+\z/, message: I18n.t(:slug_format_validation_message), on: :create
    validates :slug, length: { in: 4..63 }, on: :create
    validates :slug, uniqueness: true, on: :create
    validate :slug_is_not_reserved
    validates :logo, size: true
    validate :slack_webhook_format
    validate :slack_channel_format
    validate :custom_media_statuses_format, unless: proc { |p| p.settings.nil? || p.get_media_verification_statuses.nil? }
    validate :custom_source_statuses_format, unless: proc { |p| p.settings.nil? || p.get_source_verification_statuses.nil? }
    validate :checklist_format
  end
end
