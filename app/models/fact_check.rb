class FactCheck < ApplicationRecord
  belongs_to :user
  belongs_to :claim_description

  before_validation :set_user, on: :create
  validates_presence_of :summary, :title, :user, :claim_description
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true

  private

  def set_user
    self.user ||= User.current
  end
end
