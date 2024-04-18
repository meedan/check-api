class Explainer < ApplicationRecord
  include Article

  belongs_to :team

  has_annotations

  before_validation :set_team
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_presence_of :team

  def notify_bots
  end

  private

  def set_team
    self.team ||= Team.current unless Team.current.nil?
  end
end
