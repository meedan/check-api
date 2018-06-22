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
    validate :checklist_format
  end
end
